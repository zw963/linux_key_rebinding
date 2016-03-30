# -*- coding:utf-8; mode:ruby; -*-

require 'rbindkeys/key_event_handler/configure'
require 'rbindkeys/key_mapper'

module Rbindkeys
  # retrive key binds with key event
  class KeyEventHandler
    include Revdev

    LOG = LogUtils.get_logger name

    # device operator, 在这个对象之上调用方法来发送按键事件.
    attr_reader :operator

    #
    # 下面的 resolver 表示 自定义键绑定 <=> 实际发送的事件 的关系。
    #

    # defaulut key bind set which retrive key binds with a key event
    # 一大堆默认的键绑定.(所有的 application 通用)
    attr_reader :default_bind_resolver

    # current key bind set which retrive key binds with a key event
    # 当前 application 的键绑定, 其默认值为 default_bind_resolver
    attr_reader :bind_resolver

    # a hash (key:WindowMatcher, val:BindResolver) to switch BindResolver
    # by the title or app_name of active window
    # 一个哈希映射，窗口标题 <=> 生效的 resolver
    attr_reader :window_bind_resolver_map

    # proccessed resolver before bind_resolver
    # 全局换绑，仅仅支持单键换绑，例如：交换 Capslock 与 Ctrl.
    attr_reader :pre_bind_resolver

    # code set of pressed key on the event device
    # 当前 Event 发生时，所有被按下的键的 code 集合。(从 operator 导出)
    # 从 operator 中导出的 pressed_key_set.
    attr_reader :pressed_key_set

    # pressed key binds
    # 当前激活的组合键。(怎么获取到的？)
    attr_reader :active_bind_set

    # 这块代码很难理清，简单的了解下就好了。
    # operator 是用来发送 input 事件的 Class.
    # 将 operator 作为参数，传入当前类，做了以下几件事情：

    # 1. 加载使用 Ruby 写的 config 文件.
    #    这个 config 支持一些自定义的用法，这些用法的定义来自于：
    #    lib/key_event_handler/configure.rb

    # 2. expose 了一个 handle 方法，根据状态不同调用不同的方法。
    #    - handle_release_event
    #    - handle_press_event
    #    - handle_pressing_event
    #    所有的这些方法，会返回一个特定的符号(:through, :ignore)
    #    根据这个符号，再决定是否需要发送 InputEvent 到 Uinput 设备。
    #    这里所谓的 handle, 其实只是根据不同的 config 选项(:through, :ignore)

    def initialize(device_operator)
      @operator = device_operator
      @default_bind_resolver = BindResolver.new
      @window_bind_resolver = nil
      @bind_resolver = @default_bind_resolver
      @window_bind_resolver_map = []
      @pre_bind_resolver = {}
      @pressed_key_set = []
      @active_bind_set = []
    end
    
    # 加载 ruby 配置文件。
    def load_config(file)
      code = File.read file
      instance_eval code, file
    end

    def handle(event)
      if LOG.info?
        LOG.info ''
        LOG.info "read\t#{KeyEventHandler.get_state_by_value event} " +
          "#{event.hr_code}(#{event.code})"
      end

      # handle pre_key_bind_set
      event.code = (@pre_bind_resolver[event.code] or event.code)

      # switch to handle event with event.value
      result =
        case event.value
        when 0 then handle_release_event event
        when 1 then handle_press_event event
        when 2 then handle_pressing_event event
        else fail UnknownKeyValue, "expect 0, 1 or 2 as event.value(#{event.value})"
        end

      case result
      when :through
        fill_gap_pressed_state event if event.value == 1
        # 当执行 handle 方法时，最终会调用 @operator.send_event 给 Uinput 设备发送事件。
        # 不过在 send_event 之前，会根据 value 不同，执行对应的 handle 函数。
        # 仅当这些函数返回 :through 时，才会 send event.
        @operator.send_event event
      when :ignore
        # ignore the original event
      end

      handle_pressed_keys event

      real_key_set = @pressed_key_set.map {|code| KEY_MAPPER[code] }
      virtual_key_set = @operator.pressed_key_set.map {|code| KEY_MAPPER[code] }

      LOG.info "\033[0;33mpressed_keys real:#{real_key_set} virtual:#{virtual_key_set}\033[0m" if LOG.info?
    end

    def handle_release_event(event)
      release_bind_set = []
      @active_bind_set.reject! do |key_bind|
        if key_bind.input.include? event.code
          release_bind_set << key_bind
          true
        else
          false
        end
      end

      if release_bind_set.empty?
        :through
      else
        release_bind_set.each do |kb|
          kb.output.each {|c| @operator.release_key c }
          if kb.input_recovery
            kb.input.reject {|c| c == event.code }.each {|c| @operator.press_key c }
          end
        end
        :ignore
      end
    end

    def set_bind_resolver(resolver)
      old_resolver = @bind_resolver if LOG.info?
      @bind_resolver = resolver
      LOG.info "switch bind_resolver: #{old_resolver} => " +
        @bind_resolver.to_s if LOG.info?
      @bind_resolver
    end

    def handle_press_event(event)
      r = @bind_resolver.resolve event.code, @pressed_key_set

      LOG.debug "resolve result: #{r.inspect}" if LOG.debug?

      if r.is_a? KeyBind

        if @bind_resolver.two_stroke?
          set_bind_resolver (@window_bind_resolver or @default_bind_resolver)
        end

        if r.output.is_a? Array
          r.input.reject {|c| c == event.code }.each {|c| @operator.release_key c }
          r.output.each {|c| @operator.press_key c }
          @active_bind_set << r
          :ignore
        elsif r.output.is_a? BindResolver
          set_bind_resolver r.output
          :ignore
        elsif r.output.is_a? Proc
          @operator.release_modifier_key
          r.output.call event, @operator
        elsif r.output.is_a? Symbol
          r
        end
      else
        r
      end
    end

    def handle_pressing_event(_event)
      if @active_bind_set.empty?
        :through
      else
        @active_bind_set.each {|kb| kb.output.each {|c| @operator.pressing_key c } }
        :ignore
      end
    end

    def fill_gap_pressed_state(event)
      return if @operator.pressed_key_set == @pressed_key_set
      sub = @pressed_key_set - @operator.pressed_key_set
      sub.delete event.code if event.value == 0
      sub.each {|code| @operator.press_key code }
    end

    def handle_pressed_keys(event)
      if event.value == 1
        @pressed_key_set << event.code
        @pressed_key_set.sort! # TODO: do not sort. implement an bubble insertion
      elsif event.value == 0
        if @pressed_key_set.delete(event.code).nil?
          LOG.warn "#{event.code} does not exists on @pressed_keys" if LOG.warn?
        end
      end
    end

    def active_window_changed(window)
      if not window.nil?
        app_name = window.app_name
        app_class = window.app_class
        title = window.title
        @@active_window = window

        if LOG.info?
          LOG.info '' unless LOG.debug?
          LOG.info "change active_window: :app_name => \"#{app_name}\", :app_class => \"#{app_class}\", :title => \"#{title}\""
        end

        @window_bind_resolver_map.each do |matcher, bind_resolver|
          # 新建一个 matcher 对象的时候，会根据传入 window 方法的 regex 创建以下实例变量：
          # - @app_name, 例如：Navigator, gnome-terminal-server
          # - @app_class, 例如：Firefox, Gnome-terminal
          # - @title, 例如：'Notifications - Mozilla Firefox', Terminal (变化比较大)
          # 下面的方法的作用是：按照指定的顺序，进行匹配。
          next unless matcher.match? app_name, app_class, title
          if LOG.info?
            LOG.info "=> matcher :app_name => #{matcher.app_name.inspect}, :app_class => #{matcher.app_class.inspect}, :title => #{matcher.title.inspect}"
            LOG.info "   bind_resolver #{bind_resolver.inspect}"
          end
          set_bind_resolver bind_resolver
          @window_bind_resolver = bind_resolver
          return
        end
      elsif LOG.info?
        LOG.info '' unless LOG.debug?
        LOG.info 'change active_window: nil'
      end

      LOG.info '=> no matcher' if LOG.info?
      set_bind_resolver @default_bind_resolver
      @window_bind_resolver = nil
      nil
    end

    class << self
      # parse and normalize to Fixnum/Array
      def parse_code(code, depth=0)
        if code.is_a? Symbol
          code = parse_symbol code
        elsif code.is_a? Array
          fail ArgumentError, 'expect Array is the depth less than 1' if depth >= 1
          code.map! {|c| parse_code c, (depth + 1) }
        elsif code.is_a? Fixnum and depth == 0
          code = [code]
        elsif not code.is_a? Fixnum
          fail ArgumentError, 'expect Symbol / Fixnum / Array'
        end
        code
      end

      # TODO: convert :j -> KEY_J, :ctrl -> KEY_LEFTCTRL
      def parse_symbol(sym)
        unless sym.is_a? Symbol
          fail ArgumentError, 'expect Symbol / Fixnum / Array'
        end
        Revdev.const_get sym
      end

      # 返回 Event 的状态.
      def get_state_by_value(ev)
        case ev.value
        when 0 then 'released '
        when 1 then 'pressed  '
        when 2 then 'pressing '
        end
      end
    end
  end
end
