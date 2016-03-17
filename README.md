# Linux Key Rebinding:  Linux key rebinding tools, config is base on application, individually

# Thanks

### This package is base on following awesome open source project in github.

### [rbindkeys](https://github.com/kui/rbindkeys)

### [revdev](https://github.com/kui/revdev)

### [ruinput](https://github.com/kui/ruinput)

### [active_window_x](https://github.com/kui/active_window_x)

### [traveling-ruby](https://github.com/phusion/traveling-ruby)

# Improve for old rbindkeys.

- Can be use out of the box in X86_64 linux, i386 is current not support.
- No compile is need.
- Refactor old(not active)rebindkeys, keep going ...
- Lots of functions improve.

# How to start

1. Download package.

   ```sh
   $ git clone https://github.com/zw963/linux_key_rebinding $HOME/linux_key_rebinding
   ```

2. Create and edit your's config file $HOME/.rbindkeys.rb, you can found a sample in example directory.

3. Start as daemon with

   ```sh
   $: $HOME/linux_key_rebinding/bin/rbindkeys 'Your keyboard description' --daemon
   ```

    For boot autorun with no sudo password, you need add'
    current user to /etc/sudoers with following command:'
     $CURRENT_USER ALL=(ALL) NOPASSWD: ALL |sudo tee -a /etc/sudoers"

   this need sudo privilege, if you want boot autorun with no sudo password, 
   you need add current user to /etc/sudoers with following command:

   ```sh
   $: echo $CURRENT_USER ALL=(ALL) NOPASSWD: ALL |sudo tee -a /etc/sudoers
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
