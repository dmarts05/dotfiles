#!/bin/bash

# Kill all systray icons, polkit and lock
sleep 1 && (killall pa-applet && killall nm-applet && killall polkit-gnome-authentication-agent-1 && killall xss-lock)

# Start systray icons, polkit and lock
sleep 2 && (pa-applet & nm-applet --indicator & /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 & xss-lock i3lock &)
