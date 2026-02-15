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

-- Monitor & Cursor
awful.spawn.with_shell("autorandr --change")
awful.spawn.with_shell("xsetroot -cursor_name left_ptr")

-- Services
run_once("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")
run_once("gnome-keyring-daemon -sd")
run_once("xss-lock -- " .. config.apps.lock .. " -n")
run_once("xautolock -time 15 -locker 'systemctl suspend'")

-- Input Configuration Logic (Replaces input_setup.sh)
local function configure_input()
    awful.spawn.with_shell("setxkbmap es")
    awful.spawn.with_shell("xset r rate 210 40")
    awful.spawn.with_shell("numlockx on")

    awful.spawn.easy_async_with_shell("xinput --list", function(stdout)
        for line in stdout:gmatch("[^\r\n]+") do
            local id = line:match("id=(%d+)")
            if id then
                local lower_line = line:lower()
                -- Mouse Logic: Pointer, not XTEST/Keyboard/Touchpad
                if lower_line:match("slave.*pointer") and 
                   not lower_line:match("xtest") and 
                   not lower_line:match("keyboard") and 
                   not lower_line:match("touchpad") and 
                   not lower_line:match("trackpad") and 
                   not lower_line:match("synaptics") then
                       
                    awful.spawn("xinput set-prop " .. id .. " 'libinput Accel Profile Enabled' 0, 1")
                    awful.spawn("xinput set-prop " .. id .. " 'libinput Accel Speed' 0")
                end

                -- Touchpad Logic
                if lower_line:match("touchpad") or lower_line:match("synaptics") or lower_line:match("trackpad") then
                    awful.spawn("xinput set-prop " .. id .. " 'libinput Natural Scrolling Enabled' 1")
                    awful.spawn("xinput set-prop " .. id .. " 'libinput Tapping Enabled' 1")
                    awful.spawn("xinput set-prop " .. id .. " 'libinput Disable While Typing Enabled' 1")
                end
            end
        end
    end)
end

-- Run immediately
configure_input()

-- Watch for new devices
local input_timer = nil
awful.spawn.with_line_callback("udevadm monitor --udev --subsystem-match=input", {
    stdout = function(line)
        if line:match("add") then
            if input_timer then input_timer:stop() end
            input_timer = gears.timer.start_new(1.0, function()
                configure_input()
                naughty.notify({ 
                    title = "New Device Detected", 
                    text = "Input settings applied.",
                    timeout = 2,
                    icon = "input-mouse" 
                })
                input_timer = nil
                return false
            end)
        end
    end
})