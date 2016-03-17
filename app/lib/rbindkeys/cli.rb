# -*- coding:utf-8; mode:ruby; -*-

module Rbindkeys
  SUMMARY = 'key remapper for Linux which is configured in ruby'.freeze

  # a class is executed by bin/rbindkeys
  class CLI
    EVDEVS = '/dev/input/event*'.freeze

    # if @cmd == :observe then CLI execute to observe a given event device
    # else if @cmd == :ls then CLI list event devices
    # (default: :observe)
    @cmd = :observe

    # a location of a config file (default: "~/.rbindkeys.rb")
    @config = "#{ENV['HOME']}/.rbindkeys.rb"

    @usage = SUMMARY

    class << self
      require 'optparse'
      attr_reader :cmd, :config

      # 这里是入口函数, rbindkeys 通过这个来调用。
      def main(args)
        begin
          # 传入的参数，首先交给 parse_opt 来处理。
          # -c 将指定 @config, 调用默认的 @cmd
          # -l，-e 将指定 @cmd
          parse_opt! args
        rescue OptionParser::ParseError => e
          puts "ERROR #{e}"
          err
        end

        method(@cmd).call(args)
      end

      def err(code=1)
        puts @usage
        exit code
      end

      def parse_opt!(args)
        opt = OptionParser.new <<BANNER
#{SUMMARY}
Usage: sudo #{$0} [--config file] #{EVDEVS}
   or: sudo #{$0} --evdev-list
BANNER
        opt.version = VERSION
        opt.on '-l', '--evdev-list', 'a list of event devices' do
          @cmd = :ls
        end
        opt.on '-c VAL', '--config VAL', 'specifying your configure file' do |v|
          @config = v
        end
        opt.on '-e', '--print-example', 'print an example config' do |_v|
          @cmd = :print_example
        end

        opt.parse! args

        @usage = opt.help
      end

      def observe(args)
        if args.length != 1
          puts 'ERROR invalid arguments'
          err
        end
        # 接受两个参数，第一个是 config, 第二个是 event 设备，e.g. /dev/input/event1
        # 调用 start 启动 loop.
        Observer.new(@config, args.first).start
      end

      def ls(_args)
        require 'revdev'

        Dir.glob(EVDEVS).sort do |a, b|
          am = a.match(/[0-9]+$/)
          bm = b.match(/[0-9]+$/)
          ai = am[0] ? am[0].to_i : 0
          bi = bm[0] ? bm[0].to_i : 0
          ai <=> bi
        end.each do |f|
          begin
            e = Revdev::EventDevice.new f
            puts "#{f}:	#{e.device_name} (#{e.device_id.hr_bustype})"
          rescue => ex
            puts ex
          end
        end
      end

      def print_example(_args)
        dir = File.dirname File.expand_path __FILE__
        dir = File.expand_path File.join dir, '..', '..', 'sample'
        file = File.join dir, 'emacs.rb'
        IO.foreach file do |line|
          puts "# #{line}"
        end
      end
    end
  end # of class Runner
end
