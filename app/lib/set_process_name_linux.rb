# -*- coding: utf-8; mode:ruby; -*-

require 'fiddle'

def set_process_name_linux(name)
  handle = defined?(DL::Handle) ? DL::Handle : Fiddle::Handle

  Fiddle::Function.new(
    handle['prctl'.freeze], [
      Fiddle::TYPE_INT, Fiddle::TYPE_VOIDP,
      Fiddle::TYPE_LONG, Fiddle::TYPE_LONG,
      Fiddle::TYPE_LONG
    ], Fiddle::TYPE_INT
  ).call(15, name, 0, 0, 0)
  $PROGRAM_NAME = name
end
