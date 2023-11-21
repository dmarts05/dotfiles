#!/bin/bash

# Kill all systray icons, polkit and lock
killall pa-applet && killall cbatticon && killall nm-applet && killall polkit-gnome-authentication-agent-1 && killall xss-lock

# Start systray icons, polkit and lock
sleep 0.5 && (pa-applet & cbatticon & nm-applet --indicator & /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 & xss-lock i3lock &)

# Loop to keep running pa-applet until it works
while ! pgrep -x "pa-applet" > /dev/null; do
    pa-applet &
    sleep 0.5
done
