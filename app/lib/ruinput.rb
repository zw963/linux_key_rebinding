# -*- coding:utf-8; mode:ruby; -*-

require "ruinput/version"
require "ruinput/ruinput.#{RbConfig::CONFIG['ruby_version']}.#{RbConfig::CONFIG["DLEXT"]}"

require "ruinput/uinput_user_dev"
require "ruinput/uinput_device"

module Ruinput
  class UinputUserDev;end
  class UinputDevice;end
end
