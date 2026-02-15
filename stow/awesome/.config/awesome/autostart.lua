local awful = require("awful")
local gears = require("gears")
local naughty = require("naughty")
local config = require("config")

local function run_once(cmd)
    local findme = cmd
    local firstspace = cmd:find(" ")
    if firstspace then
        findme = cmd:sub(0, firstspace - 1)
    end
    awful.spawn.with_shell(string.format("pgrep -u $USER -x %s > /dev/null || (%s)", findme, cmd))
end

-- Display and Input Setup
awful.spawn.with_shell("autorandr --change")
awful.spawn.with_shell("xsetroot -cursor_name left_ptr")
awful.spawn.with_shell("numlockx on")

-- Services
run_once("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")
run_once("gnome-keyring-daemon -sd")
run_once("xss-lock -- " .. config.apps.lock .. " -n")
run_once("xautolock -time 15 -locker 'systemctl suspend'")
