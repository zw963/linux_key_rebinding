# -*- coding:utf-8; mode:ruby; -*-

require 'revdev'

module Rbindkeys
  # device operations like send key event, send LED event, etc.
  class DeviceOperator
    LOG = LogUtils.get_logger name

    # real event device
    attr_reader :device

    # uinput device
    attr_reader :virtural

    # key code set which was send press event but is not send release event
    attr_reader :pressed_key_set

    def initialize(dev, vdev)
      @device = dev
      @virtual = vdev
      @pressed_key_set = []
    end

    #
    # 定义了三个常规按键操作，release_key(释放), press_key(按下), pressing_key(一直按着不放)
    #
    def release_key(code)
      send_key code, 0
    end

    def press_key(code)
      send_key code, 1
    end

    def pressing_key(code)
      send_key code, 2
    end

    def combination_key(*code)
      code.each {|key| press_key key }
      send_event Revdev::EV_SYN, 0, 0 # flush the event buffer
      code.reverse_each {|key| release_key key }
      send_event Revdev::EV_SYN, 0, 0
    end

    #
    # 如何发送一个按键操作？发送一个 EV_KEY 类型事件, 并且传递一个代表按键的 code 即可。
    #
    def send_key(code, state)
      # 事件类型，具体按键的code, 这个按键的值。
      send_event Revdev::EV_KEY, code, state
    end

    def release_modifier_key
      # 29 97 CTRL, 56 100 ALT, auto release control & alt.
      [29, 97, 56, 100].each {|code| send_key code, 0 }
    end

    def release_shift_key
      [42, 54].each {|code| send_key code, 0 }
    end

    #
    # send_event 具体做的事情是：
    # 1. 新建一个 Redev::InputEvent(如果不存在的话), 即：确保只建立一个设备即可。
    # 2. 当调用 send_event 时，将传入的参数(代表某个输入操作), 填入 InputEvent 的对应字段。
    # 3. 立即将这个 Event 写入传入的那个 Uinput 设备。(通过 Uinput 导入的 write_input_event 方法。)
    # 4. 除此之外，在事件反复发生时，会维护一个 @pressed_key_set, 表示被持续按下的键的集合。
    #    - 一直按着不放，不升级。
    #    - 按下时，加入 @pressed_key_set
    #    - 弹起时，释放 @pressed_key_set
    #    这个集合会通过访问器方法暴露到外部.
    #    注意：这个集合指的是，当某个键被按下时(事件发生时), 集合的内容。
    #    此时，可能会有之前的另一个时间，已经为集合加入了一个元素。
    #    例如：按下 CTRL 不放, 集合插入 KEY_CTRL.
    #          此时再按下 A 不放，集合会插入 KEY_A.
    def send_event(*args)
      event =
        case args.length
        when 1 then args[0]
        when 3 then
          @cache_input_event ||= Revdev::InputEvent.new nil, 0, 0, 0
          @cache_input_event.type = args[0]
          @cache_input_event.code = args[1]
          @cache_input_event.value = args[2]
          @cache_input_event
        else fail ArgumentError, 'expect a InputEvent or 3 Fixnums (type, code, state)'
        end

      dev = case event.type
            when Revdev::EV_KEY then @virtual
            when Revdev::EV_LED then @device
            else @virtual
            end

      update_pressed_key_set event
      dev.write_input_event event
      LOG.info "write\t#{KeyEventHandler.get_state_by_value event} " +
        "#{event.hr_code}(#{event.code})" if LOG.info?
    end

    def update_pressed_key_set(event)
      if event.type == Revdev::EV_KEY
        case event.value
        when 0 then @pressed_key_set.delete event.code
        when 1 then @pressed_key_set << event.code
        when 2 then # do nothing
        else fail UnknownKeyValue, 'expect 0, 1 or 2'
        end
      end
    end
  end
end
