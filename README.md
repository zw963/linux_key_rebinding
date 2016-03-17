# Linux Key Rebinding:  Linux key rebinding tools, config is base on application, individually, can be use out of the box

# Thanks to

This package is base on following awesome open source project in github.

[rbindkeys](https://github.com/kui/rbindkeys)

[revdev](https://github.com/kui/revdev)

[ruinput](https://github.com/kui/ruinput)

[traveling-ruby](https://github.com/phusion/traveling-ruby)

# Purpose

- Can be use out of the box in X86_64 linux, Just throw into one directory, and run it.

# How to start

1. Download package.

```sh
$ git clone https://github.com/zw963/linux_key_rebinding
```

2. Edit your's config in $HOME/.rbindkeys.rb, you can found a sample in example directory.

3. Start as daemon with
```sh
$: rbindkeys 'Your keyboard description' --daemon
```

your keybaord description can be found with:
```sh
$: rbindkeys -l

/dev/input/event0:	AT Translated Set 2 keyboard (BUS_I8042)
/dev/input/event1:	PS/2 Generic Mouse (BUS_I8042)
/dev/input/event2:	Sleep Button (BUS_HOST)
/dev/input/event3:	Lid Switch (BUS_HOST)
...
```

Here `AT Translated Set 2 keyboard` is your keyboard description.
it is not changed when you switch diffrence linux distribtion.

# How to stop daemon

```sh
$: pkill rbindkeys
```
