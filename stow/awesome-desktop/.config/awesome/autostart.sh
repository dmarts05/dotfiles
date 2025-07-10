#!/bin/bash

run() {
    if ! pgrep -f "$1"; then
        "$@" &
    fi
}

run "/usr/lib/xfce-polkit/xfce-polkit"
run "nm-applet" --indicator
run "volumeicon"
run "xss-lock" -- "i3lock" -c "#1e1e2e"

xrandr \
  --output DP-0 --primary --mode 1920x1080 --rate 170 --pos 0x0 --rotate normal \
  --output DP-1 --off \
  --output DP-2 --off \
  --output DP-3 --off \
  --output HDMI-0 --mode 1920x1080 --pos 1920x106 --rotate normal \
  --output DP-4 --off \
  --output DP-5 --off
