# -*- coding: utf-8; mode:ruby; -*-

# Copy this file as $HOME/.rbindkeys.rb.

# NOTICE: REMOVE ALL your's .Xmodmap, .inputrc before use this.

#
# ============================== global default binding start ==============================
#

# capslock as ctrl, and rightalt as capslock, replace .Xmodmap.
pre_bind_key KEY_CAPSLOCK, KEY_LEFTCTRL
pre_bind_key KEY_RIGHTALT, KEY_CAPSLOCK

# bind Ctrl+B => left
bind_key [KEY_LEFTCTRL, KEY_B], KEY_LEFT
# bind Ctrl+F => right
bind_key [KEY_LEFTCTRL, KEY_F], KEY_RIGHT

# bind Alt+B => Ctrl+left
bind_key [KEY_LEFTALT, KEY_B], [KEY_LEFTCTRL, KEY_LEFT]
# bind Alt+F => Ctrl+right
bind_key [KEY_LEFTALT, KEY_F], [KEY_LEFTCTRL, KEY_RIGHT]

# paste
bind_key [KEY_LEFTCTRL, KEY_Y], [KEY_LEFTSHIFT, KEY_INSERT]

#
# ============================== global default binding end ==============================
#

# For browser, will overwrite glboal default keybinding.
window(@default_bind_resolver, :app_class => /Firefox$|^chromium-browser$|^google-chrome$/) do
  bind_key [KEY_LEFTCTRL, KEY_S], [KEY_LEFTCTRL, KEY_F]
end

def terminal_global
  # enlarge font
  bind_key [KEY_LEFTCTRL, KEY_EQUAL], [KEY_LEFTSHIFT, KEY_LEFTCTRL, KEY_EQUAL]

  # bind Ctrl+. to output a ` => ', Here use block form.
  bind_key [KEY_LEFTCTRL, KEY_DOT] do |_ev, op|
    # release recent pressed modifier key first. (maybe it is a bug.)
    op.release_key KEY_LEFTCTRL

    # press space key
    op.press_key KEY_SPACE
    op.release_key KEY_SPACE

    # press equal key
    op.press_key KEY_EQUAL
    op.release_key KEY_EQUAL

    # press combination key, can be any combination.
    # here press Shift+. to output a  >
    op.combination_key KEY_LEFTSHIFT, KEY_DOT

    # press space key
    op.press_key KEY_SPACE
    op.release_key KEY_SPACE
  end
end

terminal_app_class = /(terminal|XTerm|Terminator)$/

# special config must be defined before general.
# e.g. nano is run in terminal, must be defined before terminal.
# for following script is take effect, you need change current termianl title
# to `nano', you can do this with following bash function.

# function set_terminal_title () {
#   echo -en "\033]0;$*\a"
# }

# set_termianl_title nano

# For nano, app_class is Terminal, name is nano.
window(@default_bind_resolver, :title => /nano/, :app_class => terminal_app_class) do
  # copy
  bind_key [KEY_LEFTALT, KEY_W], [KEY_LEFTSHIFT, KEY_LEFTALT, KEY_6]
  # paste override global default paste.
  bind_key [KEY_LEFTCTRL, KEY_Y], [KEY_LEFTCTRL, KEY_U]

  terminal_global
end

# For Terminal, must defined after nano
window(@default_bind_resolver, :app_class => terminal_app_class) do
  # copy
  bind_key [KEY_LEFTALT, KEY_W], [KEY_LEFTSHIFT, KEY_LEFTCTRL, KEY_C]
  # paste use global default paste.

  terminal_global
end
