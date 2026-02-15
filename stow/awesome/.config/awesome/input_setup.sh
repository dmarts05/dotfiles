#!/bin/bash

# 1. Keyboard
setxkbmap es
xset r rate 210 40
numlockx on

# 2. Mouse Logic (Target Keychron/Gaming Mice, Ignore Keyboards/Touchpads)
# We use the robust grep chain to find only true pointers
mouse_ids=$(xinput --list | grep "slave .* pointer" | grep -v "XTEST" | grep -v "Keyboard" | grep -vi "Touchpad" | grep -vi "Trackpad" | grep -vi "Synaptics" | grep -o 'id=[0-9]*' | cut -d= -f2)

for id in $mouse_ids; do
    # Force No Accel (Flat Profile)
    xinput set-prop "$id" "libinput Accel Profile Enabled" 0, 1 2>/dev/null
    xinput set-prop "$id" "libinput Accel Speed" 0 2>/dev/null
done

# 3. Touchpad Logic
touchpad_ids=$(xinput --list | grep -iE "touchpad|synaptics|trackpad" | grep -o 'id=[0-9]*' | cut -d= -f2)

for id in $touchpad_ids; do
    xinput set-prop "$id" "libinput Natural Scrolling Enabled" 1 2>/dev/null
    xinput set-prop "$id" "libinput Tapping Enabled" 1 2>/dev/null
    xinput set-prop "$id" "libinput Disable While Typing Enabled" 1 2>/dev/null
done