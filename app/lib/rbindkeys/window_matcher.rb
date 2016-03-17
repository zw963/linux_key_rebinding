# -*- coding:utf-8; mode:ruby; -*-
#
# matcher for windows to use the app_class(app_name), title of the windows
#

module Rbindkeys
  class WindowMatcher
    attr_reader :app_name, :app_class, :title

    def initialize(h)
      # @app_name = (h[:class] or h[:app_name] or h[:app_class])
      # @title = (h[:title] or h[:name])

      # h 是传入 window 方法的第二个参数，总是一个哈希。
      # 这里取出哈希对应的 regex.
      @app_name = h[:app_name]
      @app_class = h[:app_class]
      @title = h[:title]

      # TODO: 这里到底是啥意思？ 之前以为只能一个条件，看样子不是这样。
      if not @app_name.nil? and not @title.nil?
        fail ArgumentError, 'expect to be given :class, :app_name,' +
          ' :app_class, :title or :name '
      end
    end

    # 这个方法的作用是：
    # 只要指定了对应的 regex, 就要和窗口对应的属性进行匹配。
    def match?(app_name, app_class, title)
      cond1 = @app_name.nil? || match_app_name?(app_name)
      cond2 = @app_class.nil? || match_app_class?(app_class)
      cond3 = @title.nil? || match_title?(title)

      cond1 and cond2 and cond3
    end

    def match_app_class?(class_name)
      class_name and class_name.match @app_class
    end

    def match_app_name?(app_name)
      app_name and app_name.match @app_name
    end

    def match_title?(title)
      title and title.match @title
    end
  end
end
