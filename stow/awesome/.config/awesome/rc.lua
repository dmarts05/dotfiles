pcall(require, "luarocks.loader")

-- [NEW] Environment Variables (X11 / Nvidia / Theming)
local glib = require("lgi").GLib

-- 1. Session Type
glib.setenv("XDG_CURRENT_DESKTOP", "awesome", true)
glib.setenv("XDG_SESSION_DESKTOP", "awesome", true)
glib.setenv("XDG_SESSION_TYPE", "x11", true)

-- 2. Force X11 Backends
glib.setenv("GDK_BACKEND", "x11", true)
glib.setenv("QT_QPA_PLATFORM", "xcb", true)
glib.setenv("SDL_VIDEODRIVER", "x11", true)

-- 3. Qt Theming
glib.setenv("QT_QPA_PLATFORMTHEME", "qt6ct", true)
glib.setenv("QT_STYLE_OVERRIDE", "qt6ct", true)

-- 4. Nvidia / Hardware Acceleration
glib.setenv("LIBVA_DRIVER_NAME", "nvidia", true)
glib.setenv("__GLX_VENDOR_LIBRARY_NAME", "nvidia", true)

-- 5. Cursor Theme
glib.setenv("XCURSOR_THEME", "XCursor-Pro-Dark", true)
glib.setenv("XCURSOR_SIZE", "24", true)

-- Standard Awesome Imports
local gears = require("gears")
local awful = require("awful")
require("awful.autofocus")
local wibox = require("wibox")
local beautiful = require("beautiful")
local naughty = require("naughty")
local hotkeys_popup = require("awful.hotkeys_popup")
require("awful.hotkeys_popup.keys")

-- {{{ Error handling
if awesome.startup_errors then
    naughty.notify({
        preset = naughty.config.presets.critical,
        title = "Oops, there were errors during startup!",
        text = awesome.startup_errors
    })
end

do
    local in_error = false
    awesome.connect_signal("debug::error", function(err)
        if in_error then return end
        in_error = true
        naughty.notify({
            preset = naughty.config.presets.critical,
            title = "Oops, an error happened!",
            text = tostring(err)
        })
        in_error = false
    end)
end
-- }}}

-- {{{ Variable definitions
beautiful.init(string.format("%s/.config/awesome/theme.lua", os.getenv("HOME")))
awesome.set_preferred_icon_size(24)

beautiful.useless_gap = 5
beautiful.gap_single_client = true

local horizontal_spacing = 8 
local vertical_spacing = 4 
awful.mouse.snap.edge_enabled = false

local apps = {
    terminal = "alacritty",
    launcher = "rofi -show drun -theme ~/.config/rofi/config.rasi",
    browser = "helium-browser --new-window",
    file_manager = "thunar",
    music = "spotify-launcher",
    discord = "discord",
    whatsapp = "helium-browser --app=https://web.whatsapp.com/",
    screenshot = "flameshot gui",
    screenshot_full = "flameshot screen",
    lock = "i3lock -c 282828",
    bluetooth_manager = "blueberry"
}

local modkey = "Mod4"
local altkey = "Mod1"
local ctrlkey = "Control"
local shiftkey = "Shift"

awful.layout.layouts = {
    awful.layout.suit.tile.right,
}
-- }}}

-- {{{ Wibar
local mytextclock = wibox.widget.textclock(" %d/%m/%y %R ")

-- Helper: Create a widget with a tooltip
local function create_widget_with_tooltip(default_icon)
    local widget = wibox.widget.textbox()
    widget.font = "CaskaydiaMono Nerd Font 10"
    widget.text = default_icon
    widget.align = "center"
    widget.forced_width = 25
    
    local tooltip = awful.tooltip({
        objects = { widget },
        mode = "outside",
        align = "right",
        preferred_positions = {"bottom", "left"},
        margin_leftright = 10,
        margin_topbottom = 5
    })

    return widget, tooltip
end

-- 1. Volume Widget
local vol_widget, vol_tooltip = create_widget_with_tooltip("")
awful.widget.watch('pamixer --get-volume-human', 1, function(widget, stdout)
    local vol_str = stdout:gsub("\n", "")
    local vol_num = tonumber(vol_str:match("(%d+)"))
    vol_tooltip.text = "Volume: " .. vol_str
    if vol_str == "muted" or (vol_num and vol_num == 0) then
        widget.text = "󰝟"
    elseif vol_num and vol_num < 33 then
        widget.text = ""
    elseif vol_num and vol_num < 66 then
        widget.text = ""
    else
        widget.text = ""
    end
end, vol_widget)

vol_widget:buttons(gears.table.join(
    awful.button({ }, 1, function() awful.spawn("pamixer -t") end),
    awful.button({ }, 3, function() awful.spawn("pavucontrol") end),
    awful.button({ }, 4, function() awful.spawn("pamixer -i 5") end),
    awful.button({ }, 5, function() awful.spawn("pamixer -d 5") end)
))

-- 2. Battery Widget
local bat_widget, bat_tooltip = create_widget_with_tooltip("󰁹")
awful.widget.watch("bash -c 'cat /sys/class/power_supply/BAT0/capacity 2>/dev/null && cat /sys/class/power_supply/BAT0/status 2>/dev/null'", 30, function(widget, stdout)
    local capacity = tonumber(stdout:match("(%d+)"))
    
    if not capacity then
        bat_widget.visible = false
        return
    end

    bat_widget.visible = true
    local status = stdout:match("Discharging") and "Discharging" or "Charging"
    local is_charging = status == "Charging"

    bat_tooltip.text = "Battery: " .. capacity .. "% (" .. status .. ")"

    local icons = { "󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹" }
    local charge_icons = { "󰢜", "󰂆", "󰂇", "󰂈", "󰢝", "󰂉", "󰢞", "󰂊", "󰂋", "󰂅" }

    local index = math.ceil(capacity / 10)
    if index == 0 then index = 1 end
    if index > 10 then index = 10 end

    widget.text = is_charging and charge_icons[index] or icons[index]
end, bat_widget)

-- 3. Network Widget
local net_widget, net_tooltip = create_widget_with_tooltip("󰤮")
awful.widget.watch("bash -c 'nmcli -t -f TYPE,NAME connection show --active | head -n1'", 5, function(widget, stdout)
    local type, name = stdout:match("([^:]+):(.+)")
    name = name and name:gsub("\n", "") or "Disconnected"
    if not type then
        widget.text = "󰤮"
        net_tooltip.text = "Disconnected"
    elseif type == "802-11-wireless" then
        widget.text = "󰤨"
        net_tooltip.text = "SSID: " .. name
    elseif type == "802-3-ethernet" then
        widget.text = "󰀂"
        net_tooltip.text = "Ethernet: " .. name
    else
        widget.text = "󰒄"
        net_tooltip.text = "Connection: " .. name
    end
end, net_widget)

net_widget:buttons(gears.table.join(
    awful.button({ }, 1, function() awful.spawn(apps.terminal .. " -e nmtui") end)
))

-- 4. Bluetooth Widget
local bt_widget, bt_tooltip = create_widget_with_tooltip("󰂲")
local bt_cmd = "bash -c 'cat /sys/class/bluetooth/hci0/rfkill*/state 2>/dev/null'"

awful.widget.watch(bt_cmd, 5, function(widget, stdout)
    local state = tonumber(stdout:match("(%d)"))
    
    if not state then
        awful.spawn.easy_async_with_shell("ls /sys/class/bluetooth/ | grep hci", function(ls_out)
            if ls_out == "" then bt_widget.visible = false else bt_widget.visible = true end
        end)
        widget.text = "󰂲"
        bt_tooltip.text = "Bluetooth: Not Found"
        return
    end

    bt_widget.visible = true

    if state == 1 then
        widget.text = "󰂯"
        bt_tooltip.text = "Bluetooth: Powered On"
    else
        widget.text = "󰂲"
        bt_tooltip.text = "Bluetooth: Powered Off"
    end
end, bt_widget)

bt_widget:buttons(gears.table.join(
    awful.button({ }, 1, function() awful.spawn(apps.bluetooth_manager) end)
))

local taglist_buttons = gears.table.join(
    awful.button({}, 1, function(t) t:view_only() end),
    awful.button({ modkey }, 1, function(t) if client.focus then client.focus:move_to_tag(t) end end),
    awful.button({}, 3, awful.tag.viewtoggle),
    awful.button({ modkey }, 3, function(t) if client.focus then client.focus:toggle_tag(t) end end),
    awful.button({}, 4, function(t) awful.tag.viewnext(t.screen) end),
    awful.button({}, 5, function(t) awful.tag.viewprev(t.screen) end)
)

awful.screen.connect_for_each_screen(function(s)
    if beautiful.wallpaper then
        gears.wallpaper.maximized(beautiful.wallpaper, s, true)
    end

    awful.tag({ "1", "2", "3", "4", "5", "6", "7", "8", "9" }, s, awful.layout.layouts[1])

    s.mytaglist = awful.widget.taglist {
        screen  = s,
        filter  = awful.widget.taglist.filter.all,
        buttons = taglist_buttons,
        widget_template = {
            {
                {
                    id     = 'text_role',
                    widget = wibox.widget.textbox,
                    align  = 'center',
                    font   = "CaskaydiaMono Nerd Font 10", 
                },
                left   = 8,
                right  = 8,
                widget = wibox.container.margin
            },
            id     = 'background_role',
            widget = wibox.container.background,
            create_callback = function(self, c3, index, objects)
                local function update()
                    local txt = self:get_children_by_id('text_role')[1]
                    txt.text = tostring(index)
                    if c3.selected then
                        self.fg = "#d8a657"
                    elseif #c3:clients() > 0 then
                        self.fg = "#d4be98"
                    else
                        self.fg = "#665c54"
                    end
                end
                update()
                c3:connect_signal("property::selected", update)
                c3:connect_signal("tagged", update)
                c3:connect_signal("untagged", update)
            end,
            update_callback = function(self, c3, index, objects)
                local txt = self:get_children_by_id('text_role')[1]
                txt.text = tostring(index)
                if c3.selected then
                    self.fg = "#d8a657"
                elseif #c3:clients() > 0 then
                    self.fg = "#d4be98"
                else
                    self.fg = "#665c54"
                end
            end,
        }
    }

    s.mywibox = awful.wibar({ position = "top", screen = s, height = 26 }) 

    s.mywibox:setup({
        layout = wibox.layout.align.horizontal,
        expand = "none", 
        { -- Left
            layout = wibox.layout.fixed.horizontal,
            s.mytaglist,
        },
        { -- Center
            layout = wibox.layout.fixed.horizontal,
            mytextclock,
        },
        { -- Right
            layout = wibox.layout.fixed.horizontal,
            
            -- [FIX] The System Tray Constraint
            {
                widget = wibox.container.margin,
                right = 7,
                {
                    widget = wibox.container.place,
                    valign = "center",
                    {
                        widget = wibox.container.constraint,
                        strategy = "max",
                        height = 14, -- Adjusted to 14px for visibility
                        wibox.widget.systray()
                    }
                }
            },

            wibox.container.margin(bt_widget, 1, 1),
            wibox.container.margin(net_widget, 1, 1),
            wibox.container.margin(vol_widget, 1, 1),
            wibox.container.margin(bat_widget, 1, 1),
            wibox.container.margin(nil, 0, 6)
        }
    })
end)
-- }}}

-- {{{ Helper Functions for OSD
local notification_id = nil

-- Generates a text-based progress bar (e.g., [██████░░░░])
local function make_progress_bar(percent)
    local length = 15
    local filled = math.floor(percent / 100 * length)
    local bar = ""
    for i = 1, length do
        if i <= filled then bar = bar .. "█" else bar = bar .. "░" end
    end
    return bar
end

-- Displays the notification with icon and progress bar
local function notify_osd(title, text, icon, percent)
    naughty.destroy(notification_id)
    local message = text
    if percent then
        message = message .. "\n" .. make_progress_bar(percent)
    end
    
    notification_id = naughty.notify({
        title = title,
        text = message,
        icon = icon,
        timeout = 2,
        hover_timeout = 0.5,
        width = 250, -- Slightly wider for the bar
    })
end
-- }}}

-- {{{ Key bindings
local globalkeys = gears.table.join(
    awful.key({ modkey }, "s", hotkeys_popup.show_help),
    awful.key({ modkey }, "Return", function() awful.spawn(apps.terminal) end),
    awful.key({ modkey }, "space", function() awful.spawn(apps.launcher) end),
    awful.key({ modkey }, "b", function() awful.spawn(apps.browser) end),
    awful.key({ modkey }, "f", function() awful.spawn(apps.file_manager) end),
    awful.key({ modkey }, "m", function() awful.spawn(apps.music) end),
    awful.key({ modkey }, "d", function() awful.spawn(apps.discord) end),
    awful.key({ modkey }, "g", function() awful.spawn(apps.whatsapp) end),
    awful.key({ modkey, ctrlkey }, "r", awesome.restart),
    awful.key({ modkey, shiftkey }, "q", awesome.quit),
    awful.key({ modkey, ctrlkey }, "q", function() awful.spawn("systemctl poweroff") end),
    awful.key({ modkey, ctrlkey }, "n", function() awful.spawn.with_shell("pgrep -x redshift && pkill redshift || redshift -P -O 4500") end),
    awful.key({}, "Print", function() awful.spawn(apps.screenshot) end),
    awful.key({ shiftkey }, "Print", function() awful.spawn(apps.screenshot_full) end),
    
    -- Auto-Suspend Toggle
    awful.key({ modkey }, "i", function ()
        awful.spawn.easy_async_with_shell("pgrep xautolock", function(stdout)
            if stdout ~= "" then
                awful.spawn("pkill xautolock")
                notify_osd("System", "Auto-suspend DISABLED", "dialog-information")
            else
                awful.spawn("xautolock -time 15 -locker 'systemctl suspend'")
                notify_osd("System", "Auto-suspend ENABLED (15m)", "dialog-information")
            end
        end)
    end, {description = "toggle auto-suspend", group = "system"}),

    -- Audio Controls (With Progress Bar)
    awful.key({}, "XF86AudioRaiseVolume", function()
        awful.spawn.easy_async("pamixer -i 5", function()
            awful.spawn.easy_async("pamixer --get-volume", function(stdout)
                local vol = tonumber(stdout)
                notify_osd("Volume", vol .. "%", "audio-volume-high", vol)
            end)
        end)
    end, {description = "volume up", group = "hotkeys"}),

    awful.key({}, "XF86AudioLowerVolume", function()
        awful.spawn.easy_async("pamixer -d 5", function()
            awful.spawn.easy_async("pamixer --get-volume", function(stdout)
                local vol = tonumber(stdout)
                notify_osd("Volume", vol .. "%", "audio-volume-low", vol)
            end)
        end)
    end, {description = "volume down", group = "hotkeys"}),

    awful.key({}, "XF86AudioMute", function()
        awful.spawn.easy_async("pamixer -t", function()
            awful.spawn.easy_async("pamixer --get-mute", function(stdout)
                local is_muted = stdout:match("true")
                local icon = is_muted and "audio-volume-muted" or "audio-volume-high"
                local text = is_muted and "Muted" or "Unmuted"
                notify_osd("Volume", text, icon)
            end)
        end)
    end, {description = "toggle mute", group = "hotkeys"}),

    awful.key({}, "XF86AudioMicMute", function() 
        awful.spawn("pamixer --default-source -t") 
        notify_osd("Microphone", "Toggle Mute", "microphone-sensitivity-medium")
    end, {description = "toggle mic mute", group = "hotkeys"}),

    -- Media Controls
    awful.key({}, "XF86AudioPlay", function()
        awful.spawn.with_shell("playerctl play-pause")
        awful.spawn.easy_async("playerctl metadata --format '{{title}} - {{artist}}'", function(stdout)
            notify_osd("Media", stdout:gsub("\n", ""), "media-playback-start")
        end)
    end, {description = "toggle player", group = "hotkeys"}),

    awful.key({}, "XF86AudioNext", function()
        awful.spawn.with_shell("playerctl next")
        awful.spawn.easy_async("playerctl metadata --format '{{title}} - {{artist}}'", function(stdout)
            notify_osd("Next Track", stdout:gsub("\n", ""), "media-skip-forward")
        end)
    end, {description = "next track", group = "hotkeys"}),

    awful.key({}, "XF86AudioPrev", function()
        awful.spawn.with_shell("playerctl previous")
        awful.spawn.easy_async("playerctl metadata --format '{{title}} - {{artist}}'", function(stdout)
            notify_osd("Previous Track", stdout:gsub("\n", ""), "media-skip-backward")
        end)
    end, {description = "previous track", group = "hotkeys"}),

    awful.key({}, "XF86AudioStop", function() 
        awful.spawn("playerctl stop") 
        notify_osd("Media", "Stopped", "media-playback-stop")
    end, {description = "stop player", group = "hotkeys"}),

    -- Brightness Controls (Robust Detection)
    awful.key({}, "XF86MonBrightnessUp", function()
        awful.spawn.easy_async("brightnessctl set 5%+", function()
            -- 1. Get Max Brightness
            awful.spawn.easy_async("brightnessctl m", function(max_out)
                local max = tonumber(max_out)
                -- 2. Get Current Brightness
                awful.spawn.easy_async("brightnessctl g", function(curr_out)
                    local curr = tonumber(curr_out)
                    if max and curr then
                        local percent = math.floor((curr / max) * 100)
                        notify_osd("Brightness", percent .. "%", "display-brightness", percent)
                    end
                end)
            end)
        end)
    end, {description = "increase brightness", group = "hotkeys"}),

    awful.key({}, "XF86MonBrightnessDown", function()
        awful.spawn.easy_async("brightnessctl set 5%-", function()
            -- 1. Get Max Brightness
            awful.spawn.easy_async("brightnessctl m", function(max_out)
                local max = tonumber(max_out)
                -- 2. Get Current Brightness
                awful.spawn.easy_async("brightnessctl g", function(curr_out)
                    local curr = tonumber(curr_out)
                    if max and curr then
                        local percent = math.floor((curr / max) * 100)
                        notify_osd("Brightness", percent .. "%", "display-brightness", percent)
                    end
                end)
            end)
        end)
    end, {description = "decrease brightness", group = "hotkeys"}),

    -- System Toggles
    awful.key({}, "XF86Search", function() awful.spawn(apps.launcher) end,
              {description = "launcher", group = "hotkeys"}),
    
    -- Focus
    awful.key({ modkey }, "h", function() awful.client.focus.bydirection("left") end),
    awful.key({ modkey }, "l", function() awful.client.focus.bydirection("right") end),
    awful.key({ modkey }, "k", function() awful.client.focus.bydirection("up") end),
    awful.key({ modkey }, "j", function() awful.client.focus.bydirection("down") end),
    awful.key({ modkey }, "Left", function() awful.client.focus.bydirection("left") end),
    awful.key({ modkey }, "Right", function() awful.client.focus.bydirection("right") end),
    awful.key({ modkey }, "Up", function() awful.client.focus.bydirection("up") end),
    awful.key({ modkey }, "Down", function() awful.client.focus.bydirection("down") end),

    -- Move
    awful.key({ modkey, ctrlkey }, "h", function() awful.client.swap.bydirection("left") end),
    awful.key({ modkey, ctrlkey }, "l", function() awful.client.swap.bydirection("right") end),
    awful.key({ modkey, ctrlkey }, "k", function() awful.client.swap.bydirection("up") end),
    awful.key({ modkey, ctrlkey }, "j", function() awful.client.swap.bydirection("down") end),
    awful.key({ modkey, ctrlkey }, "Left", function() awful.client.swap.bydirection("left") end),
    awful.key({ modkey, ctrlkey }, "Right", function() awful.client.swap.bydirection("right") end),
    awful.key({ modkey, ctrlkey }, "Up", function() awful.client.swap.bydirection("up") end),
    awful.key({ modkey, ctrlkey }, "Down", function() awful.client.swap.bydirection("down") end),

    -- Resize
    awful.key({ modkey, shiftkey }, "h", function() awful.tag.incmwfact(-0.05) end),
    awful.key({ modkey, shiftkey }, "l", function() awful.tag.incmwfact(0.05) end),
    awful.key({ modkey, shiftkey }, "k", function() awful.client.incwfact(0.05) end),
    awful.key({ modkey, shiftkey }, "j", function() awful.client.incwfact(-0.05) end),
    awful.key({ modkey, shiftkey }, "Left", function() awful.tag.incmwfact(-0.05) end),
    awful.key({ modkey, shiftkey }, "Right", function() awful.tag.incmwfact(0.05) end),
    awful.key({ modkey, shiftkey }, "Up", function() awful.client.incwfact(0.05) end),
    awful.key({ modkey, shiftkey }, "Down", function() awful.client.incwfact(-0.05) end)
)

for i = 1, 9 do
    globalkeys = gears.table.join(globalkeys,
        awful.key({ modkey }, "#" .. i + 9, function()
            local screen = awful.screen.focused()
            local tag = screen.tags[i]
            if tag then tag:view_only() end
        end),
        awful.key({ modkey, shiftkey }, "#" .. i + 9, function()
            if client.focus then
                local tag = client.focus.screen.tags[i]
                if tag then client.focus:move_to_tag(tag) end
            end
        end)
    )
end

local clientbuttons = gears.table.join(
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

-- {{{ Notification Styling
naughty.config.defaults.position = "top_right"
naughty.config.padding = 26 
naughty.config.spacing = 13  

naughty.config.defaults.margin = 15      
naughty.config.defaults.border_width = 2 
naughty.config.defaults.shape = function(cr, w, h) 
    gears.shape.rectangle(cr, w, h) 
end

naughty.config.presets.normal.border_color = beautiful.border_focus 
naughty.config.presets.normal.bg = beautiful.bg_normal          
naughty.config.presets.normal.fg = beautiful.fg_normal          

naughty.config.presets.critical.border_color = beautiful.bg_urgent 
naughty.config.presets.critical.bg = beautiful.bg_normal       
naughty.config.presets.critical.fg = beautiful.fg_urgent       
-- }}}

root.keys(globalkeys)
-- }}}

-- {{{ Rules
awful.rules.rules = {
    -- 1. GLOBAL RULE (Applies to all windows)
    { rule = {},
      properties = {
          floating = false, -- [FORCE TILED BY DEFAULT]
          border_width = beautiful.border_width,
          border_color = beautiful.border_normal,
          focus = awful.client.focus.filter,
          raise = true,
          keys = gears.table.join(
              awful.key({ modkey }, "f", function(c) c.fullscreen = not c.fullscreen; c:raise() end),
              awful.key({ modkey }, "c", function(c) c:kill() end),
              awful.key({ modkey }, "v", awful.client.floating.toggle),
              awful.key({ modkey }, "y", function(c) c:move_to_screen() end)
          ),
          buttons = clientbuttons,
          screen = awful.screen.preferred,
          placement = awful.placement.no_overlap+awful.placement.no_offscreen
      }
    },

    -- 2. FLOATING EXCEPTIONS (Apps that SHOULD float)
    { rule_any = {
        class = { 
            "Arandr", "Blueman-manager", "Gpick", "Kruler", "MessageWin", 
            "Sxiv", "Tor Browser", "Wpa_gui", "veromix", "xtightvncviewer",
            "blueberry" 
        },
        name = { "Event Tester" },
        role = { "AlarmWindow", "ConfigManager", "pop-up" }
      }, properties = { floating = true }
    },

    -- 3. PICTURE-IN-PICTURE (Special handling)
    { rule = { name = "Picture-in-Picture" },
      properties = { floating = true, sticky = true, ontop = true },
      callback = function(c)
          c:geometry({ width = 600, height = 338 })
          awful.placement.bottom_right(c, { margins = { bottom = 40, right = 40 } })
      end
    },

    -- 4. STEAM SPECIFIC (Floats small Steam windows)
    { rule = { class = "Steam", name = "Friends List" }, properties = { floating = true, width = 460, height = 800 } },
}
-- }}}

-- {{{ Signals
client.connect_signal("manage", function(c)
    if not awesome.startup then awful.client.setslave(c) end
    if awesome.startup and not c.size_hints.user_position and not c.size_hints.program_position then
        awful.placement.no_offscreen(c)
    end
end)

client.connect_signal("property::floating", function(c)
    if not c.fullscreen then c.ontop = c.floating end
end)

client.connect_signal("mouse::enter", function(c)
    c:emit_signal("request::activate", "mouse_enter", {raise = false})
end)

client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)

-- {{{ Autostart & System Services
local function run_once(cmd)
    local findme = cmd
    local firstspace = cmd:find(" ")
    if firstspace then
        findme = cmd:sub(0, firstspace - 1)
    end
    awful.spawn.with_shell(string.format("pgrep -u $USER -x %s > /dev/null || (%s)", findme, cmd))
end

-- 1. Monitor Configuration (Using autorandr)
-- This will automatically detect if you are in 'desktop' mode and apply 165Hz
awful.spawn.with_shell("autorandr --change")

-- 2. Set Default Cursor (Standard X11 pointer)
awful.spawn.with_shell("xsetroot -cursor_name left_ptr")

-- 3. System Daemons
run_once("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")
run_once("gnome-keyring-daemon -sd")
run_once("xss-lock -- i3lock -n -c 282828")
run_once("xautolock -time 15 -locker 'systemctl suspend'")

-- 4. Input Devices (Executes your separate setup script)
local input_script = string.format("%s/.config/awesome/input_setup.sh", os.getenv("HOME"))
awful.spawn.with_shell(input_script)
-- }}}

-- {{{ Input Device Management (Dynamic & Hot-pluggable)
local input_timer = nil
local input_script = string.format("%s/.config/awesome/input_setup.sh", os.getenv("HOME"))

-- 1. Run immediately on startup to ensure current devices are configured
awful.spawn.with_shell(input_script)

-- 2. Monitor ONLY for "add" events
awful.spawn.with_line_callback("udevadm monitor --udev --subsystem-match=input", {
    stdout = function(line)
        -- [OPTIMIZATION] Only check for "add". 
        -- Unplugging (remove) doesn't require re-applying settings.
        if line:match("add") then
            
            -- Debounce: A single mouse plug-in can fire 4-5 "add" events 
            -- (for the mouse, the wheel, the macro keys, etc.)
            if input_timer then 
                input_timer:stop() 
            end
            
            -- Wait 1 second to let X11 register the new ID, then configure it
            input_timer = gears.timer.start_new(1.0, function()
                awful.spawn.with_shell(input_script)
                
                naughty.notify({ 
                    title = "New Device Detected", 
                    text = "Input settings applied.",
                    timeout = 2,
                    icon = "input-mouse" 
                })
                input_timer = nil
                return false -- Stop the timer
            end)
        end
    end
})
-- }}}
