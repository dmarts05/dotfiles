local gears = require("gears")
local awful = require("awful")
local hotkeys_popup = require("awful.hotkeys_popup")
local config = require("config")
local osd = require("ui.notifications")

local modkey = config.modkey
local apps = config.apps

-- Cross-screen focus + Mouse warping
local function focus_move(dir)
    local c = client.focus
    awful.client.focus.bydirection(dir)
    if c == client.focus then
        awful.screen.focus_bydirection(dir)
    end
    
    -- Move cursor to center of the new focused client
    gears.timer.delayed_call(function()
        if client.focus then
            local g = client.focus:geometry()
            mouse.coords({ x = g.x + g.width / 2, y = g.y + g.height / 2 }, true)
        end
    end)
end

-- Move client to direction, or to next screen if at edge
local function client_move(dir)
    local c = client.focus
    if not c then return end

    -- Check if there is a client in that direction
    awful.client.focus.bydirection(dir)
    local new_c = client.focus

    if new_c == c then
        -- Focus didn't change, so we are at the edge.
        -- Switch focus to the next monitor
        awful.screen.focus_bydirection(dir)
        local s = awful.screen.focused()
        
        -- If we successfully switched screens, move the window and get focus back
        if s ~= c.screen then
            c:move_to_screen(s)
            client.focus = c 
            c:raise()
        end
    else
        -- Client found in direction. Restore focus to original and swap.
        client.focus = c
        awful.client.swap.bydirection(dir)
    end

    -- Delay the mouse warp to allow layout recalculation
    gears.timer.delayed_call(function()
        if c and c.valid then
            local g = c:geometry()
            mouse.coords({ x = g.x + g.width / 2, y = g.y + g.height / 2 }, true)
        end
    end)
end

-- Global Keys
local globalkeys = gears.table.join(
    -- Apps
    awful.key({ modkey }, "Return", function() awful.spawn(apps.terminal) end),
    awful.key({ modkey }, "space", function() awful.spawn(apps.launcher) end),
    awful.key({ modkey }, "b", function() awful.spawn(apps.browser) end),
    awful.key({ modkey }, "f", function() awful.spawn(apps.file_manager) end),
    awful.key({ modkey }, "m", function() awful.spawn(apps.music) end),
    awful.key({ modkey }, "d", function() awful.spawn(apps.discord) end),
    awful.key({ modkey }, "g", function() awful.spawn(apps.whatsapp) end),

    -- System
    awful.key({ modkey, config.ctrlkey }, "r", awesome.restart),
    awful.key({ modkey, config.shiftkey }, "q", awesome.quit),
    awful.key({ modkey, config.ctrlkey }, "q", function() awful.spawn("systemctl poweroff") end),
    awful.key({ modkey, config.ctrlkey }, "n", function() awful.spawn.with_shell("pgrep -x redshift && pkill redshift || redshift -P -O 4500") end),
    awful.key({}, "Print", function() awful.spawn(apps.screenshot) end),
    awful.key({ config.shiftkey }, "Print", function() awful.spawn(apps.screenshot_full) end),
    
    -- Auto-Suspend Toggle
    awful.key({ modkey }, "i", function ()
        awful.spawn.easy_async_with_shell("pgrep xautolock", function(stdout)
            if stdout ~= "" then
                awful.spawn("pkill xautolock")
                osd.notify_osd("System", "Auto-suspend DISABLED", "dialog-information")
            else
                awful.spawn("xautolock -time 15 -locker 'systemctl suspend'")
                osd.notify_osd("System", "Auto-suspend ENABLED (15m)", "dialog-information")
            end
        end)
    end),

    -- Audio
    awful.key({}, "XF86AudioRaiseVolume", function()
        awful.spawn.easy_async("pamixer -i 5", function()
            awful.spawn.easy_async("pamixer --get-volume", function(stdout)
                local vol = tonumber(stdout)
                osd.notify_osd("Volume", vol .. "%", "audio-volume-high", vol)
            end)
        end)
    end),
    awful.key({}, "XF86AudioLowerVolume", function()
        awful.spawn.easy_async("pamixer -d 5", function()
            awful.spawn.easy_async("pamixer --get-volume", function(stdout)
                local vol = tonumber(stdout)
                osd.notify_osd("Volume", vol .. "%", "audio-volume-low", vol)
            end)
        end)
    end),
    awful.key({}, "XF86AudioMute", function()
        awful.spawn.easy_async("pamixer -t", function()
            awful.spawn.easy_async("pamixer --get-mute", function(stdout)
                local is_muted = stdout:match("true")
                local icon = is_muted and "audio-volume-muted" or "audio-volume-high"
                local text = is_muted and "Muted" or "Unmuted"
                osd.notify_osd("Volume", text, icon)
            end)
        end)
    end),
    awful.key({}, "XF86AudioMicMute", function() 
        awful.spawn("pamixer --default-source -t") 
        osd.notify_osd("Microphone", "Toggle Mute", "microphone-sensitivity-medium")
    end),

    -- Media
    awful.key({}, "XF86AudioPlay", function()
        awful.spawn.with_shell("playerctl play-pause")
        awful.spawn.easy_async("playerctl metadata --format '{{title}} - {{artist}}'", function(stdout)
            osd.notify_osd("Media", stdout:gsub("\n", ""), "media-playback-start")
        end)
    end),
    awful.key({}, "XF86AudioNext", function()
        awful.spawn.with_shell("playerctl next")
        awful.spawn.easy_async("playerctl metadata --format '{{title}} - {{artist}}'", function(stdout)
            osd.notify_osd("Next Track", stdout:gsub("\n", ""), "media-skip-forward")
        end)
    end),
    awful.key({}, "XF86AudioPrev", function()
        awful.spawn.with_shell("playerctl previous")
        awful.spawn.easy_async("playerctl metadata --format '{{title}} - {{artist}}'", function(stdout)
            osd.notify_osd("Previous Track", stdout:gsub("\n", ""), "media-skip-backward")
        end)
    end),
    awful.key({}, "XF86AudioStop", function() 
        awful.spawn("playerctl stop") 
        osd.notify_osd("Media", "Stopped", "media-playback-stop")
    end),

    -- Brightness
    awful.key({}, "XF86MonBrightnessUp", function()
        awful.spawn.easy_async("brightnessctl set 5%+", function()
            awful.spawn.easy_async("brightnessctl m", function(max_out)
                local max = tonumber(max_out)
                awful.spawn.easy_async("brightnessctl g", function(curr_out)
                    local curr = tonumber(curr_out)
                    if max and curr then
                        local percent = math.floor((curr / max) * 100)
                        osd.notify_osd("Brightness", percent .. "%", "display-brightness", percent)
                    end
                end)
            end)
        end)
    end),
    awful.key({}, "XF86MonBrightnessDown", function()
        awful.spawn.easy_async("brightnessctl set 5%-", function()
            awful.spawn.easy_async("brightnessctl m", function(max_out)
                local max = tonumber(max_out)
                awful.spawn.easy_async("brightnessctl g", function(curr_out)
                    local curr = tonumber(curr_out)
                    if max and curr then
                        local percent = math.floor((curr / max) * 100)
                        osd.notify_osd("Brightness", percent .. "%", "display-brightness", percent)
                    end
                end)
            end)
        end)
    end),

    -- Client Focus & Movement
    awful.key({ modkey }, "h", function() focus_move("left") end),
    awful.key({ modkey }, "l", function() focus_move("right") end),
    awful.key({ modkey }, "k", function() focus_move("up") end),
    awful.key({ modkey }, "j", function() focus_move("down") end),
    awful.key({ modkey }, "Left", function() focus_move("left") end),
    awful.key({ modkey }, "Right", function() focus_move("right") end),
    awful.key({ modkey }, "Up", function() focus_move("up") end),
    awful.key({ modkey }, "Down", function() focus_move("down") end),

    -- Client Swapping / Monitor Moving
    awful.key({ modkey, config.ctrlkey }, "h", function() client_move("left") end),
    awful.key({ modkey, config.ctrlkey }, "l", function() client_move("right") end),
    awful.key({ modkey, config.ctrlkey }, "k", function() client_move("up") end),
    awful.key({ modkey, config.ctrlkey }, "j", function() client_move("down") end),
    awful.key({ modkey, config.ctrlkey }, "Left", function() client_move("left") end),
    awful.key({ modkey, config.ctrlkey }, "Right", function() client_move("right") end),
    awful.key({ modkey, config.ctrlkey }, "Up", function() client_move("up") end),
    awful.key({ modkey, config.ctrlkey }, "Down", function() client_move("down") end),

    awful.key({ modkey, config.shiftkey }, "h", function() awful.tag.incmwfact(-0.05) end),
    awful.key({ modkey, config.shiftkey }, "l", function() awful.tag.incmwfact(0.05) end),
    awful.key({ modkey, config.shiftkey }, "k", function() awful.client.incwfact(0.05) end),
    awful.key({ modkey, config.shiftkey }, "j", function() awful.client.incwfact(-0.05) end),
    awful.key({ modkey, config.shiftkey }, "Left", function() awful.tag.incmwfact(-0.05) end),
    awful.key({ modkey, config.shiftkey }, "Right", function() awful.tag.incmwfact(0.05) end),
    awful.key({ modkey, config.shiftkey }, "Up", function() awful.client.incwfact(0.05) end),
    awful.key({ modkey, config.shiftkey }, "Down", function() awful.client.incwfact(-0.05) end)
)

-- Tag Keys
for i = 1, 9 do
    globalkeys = gears.table.join(globalkeys,
        awful.key({ modkey }, "#" .. i + 9, function()
            local screen = awful.screen.focused()
            local tag = screen.tags[i]
            if tag then tag:view_only() end
        end),
        awful.key({ modkey, config.shiftkey }, "#" .. i + 9, function()
            if client.focus then
                local tag = client.focus.screen.tags[i]
                if tag then client.focus:move_to_tag(tag) end
            end
        end)
    )
end

root.keys(globalkeys)

-- Client Buttons
return gears.table.join(
    awful.button({}, 1, function(c) c:emit_signal("request::activate", "mouse_click", {raise = true}) end),
    awful.button({ modkey }, 1, function(c)
        c:emit_signal("request::activate", "mouse_click", {raise = true})
        awful.mouse.client.move(c)
    end),
    awful.button({ modkey }, 3, function(c)
        c:emit_signal("request::activate", "mouse_click", {raise = true})
        awful.mouse.client.resize(c)
    end),
    awful.button({ modkey }, 2, function(c) awful.client.floating.toggle(c) end)
)