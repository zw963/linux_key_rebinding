# -*- coding:utf-8; mode:ruby; -*-
#
# a part of KeyEventHandler (see lib/rbindkeys/key_event_handler.rb)
#

module Rbindkeys
  class KeyEventHandler
    def active_window
      @@active_window
    end
    # pre-prosessed key codes replacement for all inputs
    # 在所有应用程序下面都会被执行的换绑键。
    # 支持两个参数：input, 输入的键绑定。output, 输出的键绑定。
    def pre_bind_key(input, output)
      # 必须是数字，这意味着仅支持单键换绑。
      unless input.is_a? Fixnum and output.is_a? Fixnum
        fail ArgumentError, 'expect Fixnum for input and output'
      end

      # 不允许重复的换绑。避免死锁。
      if @pre_bind_resolver.key? input
        fail DuplicateNodeError, "1st arg (#{input}) was already entried"
      end

      LOG.info "pre_bind_key #{input.inspect},\t#{output.inspect}" if LOG.info?

      @pre_bind_resolver[input] = output
      # 返回值没什么意义。关键是写入 @pre_bind_ersolver 哈希。
      [input, output]
    end

    # define a new key binding
    # 定义默认的按键绑定。
    # 基本步骤如下：
    # - 对 input/output 执行必要的预处理。(通过 KeyEventHandler.parse_code)
    # - 通过 bind_resolver.bind 方法，来执行真是的按键换绑。
    def bind_key(input, output=nil, resolver=@bind_resolver, &block)
      # 第一步执行预处理，KeyEventHandler.parse_code, 返回一个新的 input.
      if input.is_a? Array or input.is_a? Fixnum
        input = KeyEventHandler.parse_code input
      else
        fail ArgumentError, '1st arg expect Array / Fixnum'
      end

      if block_given?
        output = block
      elsif output.nil?
        fail ArgumentError, 'expect 1 arg with a block / 2 args'
      elsif output.kind_of? BindResolver
      elsif output.is_a? Array or output.is_a? Fixnum
        output = KeyEventHandler.parse_code output
      elsif output == :through or output == :ignore
      else
        fail ArgumentError, '2nd arg expect Array / Fixnum / BindResolver / ' +
          'Symbol(:through/:ignore)'
      end

      LOG.info "bind_key #{input.inspect},\t#{output.inspect}\t#{resolver}" if LOG.info?

      resolver.bind input, output
    end

    # setting for 2stroke key binding
    # _input_ :: prefix key. (e.g. [KEY_LEFTCTRL, KEY_X] (C-x)
    # _resolver_ :: upper bind_resolver for fall throught
    # _block_ :: to define sub-binds on this prefix key bind
    def bind_prefix_key(input, resolver=@bind_resolver, &_block)
      fail ArgumentError, 'expect a block' unless block_given?

      input = KeyEventHandler.parse_code input
      LOG.info "bind_prefix_key #{input.inspect}\t#{resolver}" if LOG.info?
      tmp = input.clone
      tail_input = tmp.pop

      binded_resolver = resolver.just_resolve tail_input, tmp
      if binded_resolver.nil?
        binded_resolver = BindResolver.new :ignore, true
        resolver.bind input, binded_resolver
      elsif not binded_resolver.kind_of? BindResolver
        fail DuplicateNodeError, "the codes (#{input.inspect}) was already binded"
      end

      @bind_resolver = binded_resolver
      yield
      @bind_resolver = resolver
      binded_resolver
    end

    # 这个没有用到？
    # def new_bind_resolver(upper_resolver=@bind_resolver, &_block)
    #   fail ArgumentError, 'expect a block' unless block_given?

    #   new_resolver = BindResolver.new upper_resolver

    #   old_resolver = @bind_resolver
    #   @bind_resolver = new_resolver
    #   yield
    #   @bind_resolver = old_resolver

    #   new_resolver
    # end

    # switch bind_resolver if the active window match _arg_
    #
    # _upper\_resolver_ :: a upper bind_resolver, :through, :ignore
    # _arg_ :: a hash or a regexp
    #
    # ==arg
    # if a hash, which have entries :title => Regexp and/or :class => Regexp,
    # was given, this bind is active when the window title match with
    # :title's Regexp AND the window class match with :class's Regexp.
    # if a regexp was given, this bind is active when the window title match
    # with the given regexp
    def window(upper_resolver, arg)
      if upper_resolver.nil?
        upper_resolver = @bind_resolver
      elsif upper_resolver.is_a? Symbol
        upper_resolver = FixResolver.instance upper_resolver
      elsif not upper_resolver.kind_of? BindResolver
        fail ArgumentError, '1nd argument is expected to be a BindResolver or' +
          " a Symbol : #{upper_resolver}"
      end

      if arg.is_a? Regexp
        arg = { :title => arg }
      elsif arg.is_a? Hash
        arg.each do |k, v|
          unless k.is_a? Symbol and v.is_a? Regexp
            fail ArgumentError, 'the 2nd argument Hash must only have' +
              " Symbol keys and Regexp values : #{arg.inspect}"
          end
        end
      else
        fail ArgumentError, "2nd argument is expected to be a Hash or a Regexp : #{arg}"
      end

      resolver = BindResolver.new(upper_resolver)
      @window_bind_resolver_map.push [WindowMatcher.new(arg), resolver]

      if block_given?
        old_resolver = @bind_resolver
        @bind_resolver = resolver
        yield
        @bind_resolver = old_resolver
      end

      resolver
    end
  end
end
