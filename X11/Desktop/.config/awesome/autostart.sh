#!/bin/bash

# Kill all systray icons, polkit and lock
killall pa-applet && killall nm-applet && killall polkit-gnome-authentication-agent-1 && killall xss-lock

# Start systray icons, polkit and lock
sleep 0.5 && (pa-applet & nm-applet --indicator & /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 & xss-lock i3lock &)

# Rerun pa-applet if it crashes
sleep 3 && if ! pgrep -x "pa-applet" > /dev/null; then pa-applet & fi