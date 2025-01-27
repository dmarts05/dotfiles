#!/bin/bash

run() {
    if ! pgrep -f "$1"; then
        "$@" &
    fi
}

run "/usr/lib/xfce-polkit/xfce-polkit"
run "nm-applet" --indicator
run "xss-lock" -- "i3lock" -c "#1e1e2e"
