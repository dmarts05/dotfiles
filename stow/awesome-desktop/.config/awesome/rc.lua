-- If LuaRocks is installed, make sure that packages installed through it are
-- found (e.g. lgi). If LuaRocks is not installed, do nothing.
pcall(require, "luarocks.loader")

-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
require("awful.autofocus")
-- Widget and layout library
local wibox = require("wibox")
-- Theme handling library
local beautiful = require("beautiful")
-- Notification library
local naughty = require("naughty")
-- local menubar = require("menubar")
local hotkeys_popup = require("awful.hotkeys_popup")
-- Enable hotkeys help widget for VIM and other apps
-- when client with a matching name is opened:
require("awful.hotkeys_popup.keys")

-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify({
        preset = naughty.config.presets.critical,
        title = "Oops, there were errors during startup!",
        text = awesome.startup_errors
    })
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.connect_signal("debug::error", function(err)
        -- Make sure we don't go into an endless error loop
        if in_error then
            return
        end
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
-- Themes define colours, icons, font and wallpapers.
-- beautiful.init(gears.filesystem.get_themes_dir() .. "gtk/theme.lua")
beautiful.init(string.format("%s/.config/awesome/theme.lua", os.getenv("HOME")))

-- Use correct status icon size
awesome.set_preferred_icon_size(32)

-- Enable gaps
beautiful.useless_gap = 3
beautiful.gap_single_client = true

local horizontal_spacing = 4
local vertical_spacing = 8

-- Add systray spacing
beautiful.systray_icon_spacing = horizontal_spacing * 2

-- Fix window snapping
awful.mouse.snap.edge_enabled = false

-- This is used later as the default terminal and editor to run.
local terminal = "alacritty"
-- local editor = os.getenv("EDITOR") or "nvim"
-- local editor_cmd = terminal .. " -e " .. editor

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
local modkey = "Mod4"

-- Table of layouts to cover with awful.layout.inc, order matters.
awful.layout.layouts = { awful.layout.suit.tile.right, awful.layout.suit.tile.left }
-- }}}

-- {{{ Wibar

local widget_size = 20

-- Create a textclock widget
local mytextclock = wibox.widget.textclock()

-- Create a wibox for each screen and add it
local taglist_buttons = gears.table.join(awful.button({}, 1, function(t)
    t:view_only()
end), awful.button({ modkey }, 1, function(t)
    if client.focus then
        client.focus:move_to_tag(t)
    end
end), awful.button({}, 3, awful.tag.viewtoggle), awful.button({ modkey }, 3, function(t)
    if client.focus then
        client.focus:toggle_tag(t)
    end
end), awful.button({}, 4, function(t)
    awful.tag.viewnext(t.screen)
end), awful.button({}, 5, function(t)
    awful.tag.viewprev(t.screen)
end))

-- local tasklist_buttons = gears.table.join(
-- 	awful.button({}, 1, function(c)
-- 		if c == client.focus then
-- 			c.minimized = true
-- 		else
-- 			c:emit_signal("request::activate", "tasklist", {
-- 				raise = true,
-- 			})
-- 		end
-- 	end),
-- 	awful.button({}, 3, function()
-- 		awful.menu.client_list({
-- 			theme = {
-- 				width = 250,
-- 			},
-- 		})
-- 	end),
-- 	awful.button({}, 4, function()
-- 		awful.client.focus.byidx(1)
-- 	end),
-- 	awful.button({}, 5, function()
-- 		awful.client.focus.byidx(-1)
-- 	end)
-- )

local function set_wallpaper(s)
    -- Wallpaper
    if beautiful.wallpaper then
        local wallpaper = beautiful.wallpaper
        -- If wallpaper is a function, call it with the screen
        if type(wallpaper) == "function" then
            wallpaper = wallpaper(s)
        end
        gears.wallpaper.maximized(wallpaper, s, true)
    end
end

-- Re-set wallpaper when a screen's geometry changes (e.g. different resolution)
screen.connect_signal("property::geometry", set_wallpaper)

awful.screen.connect_for_each_screen(function(s)
    -- Wallpaper
    set_wallpaper(s)

    -- Each screen has its own tag table.
    awful.tag({ "1", "2", "3", "4", "5", "6", "7", "8", "9" }, s, awful.layout.layouts[1])

    -- Create a promptbox for each screen
    s.mypromptbox = awful.widget.prompt()

    -- Create an imagebox widget which will contain an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    s.mylayoutbox = awful.widget.layoutbox(s)
    s.mylayoutbox:buttons(gears.table.join(awful.button({}, 1, function()
        awful.layout.inc(1)
    end), awful.button({}, 3, function()
        awful.layout.inc(-1)
    end), awful.button({}, 4, function()
        awful.layout.inc(1)
    end), awful.button({}, 5, function()
        awful.layout.inc(-1)
    end)))
    -- Create a taglist widget
    s.mytaglist = awful.widget.taglist({
        screen = s,
        filter = awful.widget.taglist.filter.all,
        buttons = taglist_buttons
    })

    -- Create a tasklist widget
    -- s.mytasklist = awful.widget.tasklist {
    --     screen  = s,
    --     filter  = awful.widget.tasklist.filter.currenttags,
    --     buttons = tasklist_buttons
    -- }

    -- Create the wibox
    s.mywibox = awful.wibar({
        position = "top",
        screen = s
    })

    -- Add widgets to the wibox
    s.mywibox:setup({
        layout = wibox.layout.align.horizontal,
        { -- Left widgets
            layout = wibox.layout.fixed.horizontal,
            -- mylauncher,
            s.mytaglist
            -- s.mypromptbox,
        },
        s.mytasklist, -- Middle widget
        {             -- Right widgets
            layout = wibox.layout.fixed.horizontal,
            wibox.layout.margin(wibox.widget.systray(), horizontal_spacing, horizontal_spacing, vertical_spacing,
                vertical_spacing),
            wibox.layout.margin(s.mylayoutbox, horizontal_spacing, horizontal_spacing, vertical_spacing,
                vertical_spacing),
            wibox.layout.margin(mytextclock, horizontal_spacing, horizontal_spacing, vertical_spacing, vertical_spacing)
        }
    })
end)
-- }}}

-- {{{ Mouse bindings
-- root.buttons(gears.table.join(
-- 	awful.button({}, 3, function()
-- 		mymainmenu:toggle()
-- 	end)
-- awful.button({}, 4, awful.tag.viewnext),
-- awful.button({}, 5, awful.tag.viewprev)
-- ))
-- }}}

-- {{{ Key bindings
local globalkeys = gears.table.join( -- Master and column manipulation
    awful.key({ modkey }, "p", function()
        awful.tag.incnmaster(1, nil, true)
    end, {
        description = "increase the number of master clients",
        group = "layout"
    }), awful.key({ modkey, "Shift" }, "p", function()
        awful.tag.incnmaster(-1, nil, true)
    end, {
        description = "decrease the number of master clients",
        group = "layout"
    }), awful.key({ modkey }, "n", function()
        awful.tag.incncol(1, nil, true)
    end, {
        description = "increase the number of columns",
        group = "layout"
    }), awful.key({ modkey, "Shift" }, "n", function()
        awful.tag.incncol(-1, nil, true)
    end, {
        description = "decrease the number of columns",
        group = "layout"
    }), awful.key({ modkey, "Shift" }, "s", hotkeys_popup.show_help, {
        description = "show help",
        group = "awesome"
    }), -- Standard program
    awful.key({ modkey }, "Return", function()
        awful.spawn(terminal)
    end, {
        description = "open a terminal",
        group = "launcher"
    }), awful.key({ modkey, "Control" }, "r", awesome.restart, {
        description = "reload awesome",
        group = "awesome"
    }), awful.key({ modkey, "Shift" }, "q", awesome.quit, {
        description = "quit awesome",
        group = "awesome"
    }), awful.key({ modkey, "Control" }, "q", function()
        awful.spawn.with_shell("systemctl poweroff")
    end, {
        description = "poweroff awesome",
        group = "awesome"
    }), awful.key({ "Control", "Mod1" }, "l", function()
        awful.spawn.with_shell("systemctl suspend")
    end, {
        description = "suspend awesome",
        group = "awesome"
    }), awful.key({ modkey }, "Tab", function()
        awful.layout.inc(1)
    end, {
        description = "select next",
        group = "layout"
    }), awful.key({ modkey, "Shift" }, "Tab", function()
        awful.layout.inc(-1)
    end, {
        description = "select previous",
        group = "layout"
    }), -- Volume and brightness
    awful.key({}, "XF86MonBrightnessUp", function()
        awful.spawn.with_shell("brightnessctl set +5%")
    end, {
        description = "brightness up",
        group = "hotkeys"
    }), awful.key({}, "XF86MonBrightnessDown", function()
        awful.spawn.with_shell("brightnessctl set 5%-")
    end, {
        description = "brightness down",
        group = "hotkeys"
    }), awful.key({}, "XF86AudioRaiseVolume", function()
        awful.spawn.with_shell("pactl set-sink-volume @DEFAULT_SINK@ +1%")
    end, {
        description = "volume up",
        group = "hotkeys"
    }), awful.key({}, "XF86AudioLowerVolume", function()
        awful.spawn.with_shell("pactl set-sink-volume @DEFAULT_SINK@ -1%")
    end, {
        description = "volume down",
        group = "hotkeys"
    }), awful.key({}, "XF86AudioMute", function()
        awful.spawn.with_shell("pactl set-sink-mute @DEFAULT_SINK@ toggle")
    end, {
        description = "toggle mute",
        group = "hotkeys"
    }), awful.key({}, "XF86AudioPlay", function()
        awful.spawn.with_shell("playerctl play-pause media")
    end, {
        description = "play / pause",
        group = "hotkeys"
    }), awful.key({}, "XF86AudioNext", function()
        awful.spawn.with_shell("playerctl next")
    end, {
        description = "next media",
        group = "hotkeys"
    }), awful.key({}, "XF86AudioPrev", function()
        awful.spawn.with_shell("playerctl previous")
    end, {
        description = "previous media",
        group = "hotkeys"
    }), -- Rofi
    awful.key({ modkey }, "space", function()
        awful.util.spawn("rofi -show drun")
    end, {
        description = "run rofi",
        group = "launcher"
    }), -- Screenshot
    awful.key({}, "Print", function()
        awful.util.spawn("flameshot gui")
    end, {
        description = "make a screenshot",
        group = "application"
    }), -- File explorer
    awful.key({ modkey }, "e", function()
        awful.util.spawn("thunar")
    end, {
        description = "run file explorer",
        group = "application"
    }), -- Visual Studio Code
    awful.key({ modkey }, "v", function()
        awful.util.spawn("code")
    end, {
        description = "run vscode",
        group = "application"
    }), -- Music
    awful.key({ modkey }, "m", function()
        awful.util.spawn("spotify")
    end, {
        description = "run spotify",
        group = "application"
    }), -- Discord
    awful.key({ modkey }, "d", function()
        awful.util.spawn("vesktop")
    end, {
        description = "run discord",
        group = "application"
    }), -- Browser
    awful.key({ modkey }, "b", function()
        awful.util.spawn("brave")
    end, {
        description = "run browser",
        group = "application"
    }))

local clientkeys = gears.table.join( -- Resize windows (arrow keys)
    awful.key({ modkey, "Shift" }, "Up", function(c)
        if c.floating then
            c:relative_move(0, 0, 0, -10)
        else
            awful.client.incwfact(0.025)
        end
    end, {
        description = "resize Vertical -",
        group = "client"
    }), awful.key({ modkey, "Shift" }, "Down", function(c)
        if c.floating then
            c:relative_move(0, 0, 0, 10)
        else
            awful.client.incwfact(-0.025)
        end
    end, {
        description = "resize Vertical +",
        group = "client"
    }), awful.key({ modkey, "Shift" }, "Left", function(c)
        if c.floating then
            c:relative_move(0, 0, -10, 0)
        else
            awful.tag.incmwfact(-0.025)
        end
    end, {
        description = "resize Horizontal -",
        group = "client"
    }), awful.key({ modkey, "Shift" }, "Right", function(c)
        if c.floating then
            c:relative_move(0, 0, 10, 0)
        else
            awful.tag.incmwfact(0.025)
        end
    end, {
        description = "resize Horizontal +",
        group = "client"
    }), -- Resize windows (hjkl keys)
    awful.key({ modkey, "Shift" }, "k", function(c)
        if c.floating then
            c:relative_move(0, 0, 0, -10)
        else
            awful.client.incwfact(0.025)
        end
    end, {
        description = "resize Vertical -",
        group = "client"
    }), awful.key({ modkey, "Shift" }, "j", function(c)
        if c.floating then
            c:relative_move(0, 0, 0, 10)
        else
            awful.client.incwfact(-0.025)
        end
    end, {
        description = "resize Vertical +",
        group = "client"
    }), awful.key({ modkey, "Shift" }, "h", function(c)
        if c.floating then
            c:relative_move(0, 0, -10, 0)
        else
            awful.tag.incmwfact(-0.025)
        end
    end, {
        description = "resize Horizontal -",
        group = "client"
    }), awful.key({ modkey, "Shift" }, "l", function(c)
        if c.floating then
            c:relative_move(0, 0, 10, 0)
        else
            awful.tag.incmwfact(0.025)
        end
    end, {
        description = "resize Horizontal +",
        group = "client"
    }), -- Moving floating windows (arrow keys)
    awful.key({ modkey, "Mod1" }, "Down", function(c)
        c:relative_move(0, 10, 0, 0)
    end, {
        description = "floating Move Down",
        group = "client"
    }), awful.key({ modkey, "Mod1" }, "Up", function(c)
        c:relative_move(0, -10, 0, 0)
    end, {
        description = "floating Move Up",
        group = "client"
    }), awful.key({ modkey, "Mod1" }, "Left", function(c)
        c:relative_move(-10, 0, 0, 0)
    end, {
        description = "floating Move Left",
        group = "client"
    }), awful.key({ modkey, "Mod1" }, "Right", function(c)
        c:relative_move(10, 0, 0, 0)
    end, {
        description = "floating Move Right",
        group = "client"
    }), -- Moving floating windows (hjkl keys)
    awful.key({ modkey, "Mod1" }, "j", function(c)
        c:relative_move(0, 10, 0, 0)
    end, {
        description = "floating Move Down",
        group = "client"
    }), awful.key({ modkey, "Mod1" }, "k", function(c)
        c:relative_move(0, -10, 0, 0)
    end, {
        description = "floating Move Up",
        group = "client"
    }), awful.key({ modkey, "Mod1" }, "h", function(c)
        c:relative_move(-10, 0, 0, 0)
    end, {
        description = "floating Move Left",
        group = "client"
    }), awful.key({ modkey, "Mod1" }, "l", function(c)
        c:relative_move(10, 0, 0, 0)
    end, {
        description = "floating Move Right",
        group = "client"
    }), -- Moving window focus works between desktops (arrow keys)
    awful.key({ modkey }, "Down", function(c)
        awful.client.focus.global_bydirection("down")
        c:lower()
    end, {
        description = "focus next window up",
        group = "client"
    }), awful.key({ modkey }, "Up", function(c)
        awful.client.focus.global_bydirection("up")
        c:lower()
    end, {
        description = "focus next window down",
        group = "client"
    }), awful.key({ modkey }, "Right", function(c)
        awful.client.focus.global_bydirection("right")
        c:lower()
    end, {
        description = "focus next window right",
        group = "client"
    }), awful.key({ modkey }, "Left", function(c)
        awful.client.focus.global_bydirection("left")
        c:lower()
    end, {
        description = "focus next window left",
        group = "client"
    }), -- Moving window focus works between desktops (hjkl keys)
    awful.key({ modkey }, "j", function(c)
        awful.client.focus.global_bydirection("down")
        c:lower()
    end, {
        description = "focus next window up",
        group = "client"
    }), awful.key({ modkey }, "k", function(c)
        awful.client.focus.global_bydirection("up")
        c:lower()
    end, {
        description = "focus next window down",
        group = "client"
    }), awful.key({ modkey }, "l", function(c)
        awful.client.focus.global_bydirection("right")
        c:lower()
    end, {
        description = "focus next window right",
        group = "client"
    }), awful.key({ modkey }, "h", function(c)
        awful.client.focus.global_bydirection("left")
        c:lower()
    end, {
        description = "focus next window left",
        group = "client"
    }), -- Moving windows between positions works between desktops (arrow keys)
    awful.key({ modkey, "Control" }, "Left", function(c)
        awful.client.swap.global_bydirection("left")
        c:raise()
    end, {
        description = "swap with left client",
        group = "client"
    }), awful.key({ modkey, "Control" }, "Right", function(c)
        awful.client.swap.global_bydirection("right")
        c:raise()
    end, {
        description = "swap with right client",
        group = "client"
    }), awful.key({ modkey, "Control" }, "Down", function(c)
        awful.client.swap.global_bydirection("down")
        c:raise()
    end, {
        description = "swap with down client",
        group = "client"
    }), awful.key({ modkey, "Control" }, "Up", function(c)
        awful.client.swap.global_bydirection("up")
        c:raise()
    end, {
        description = "swap with up client",
        group = "client"
    }), -- Moving windows between positions works between desktops (hjkl keys)
    awful.key({ modkey, "Control" }, "h", function(c)
        awful.client.swap.global_bydirection("left")
        c:raise()
    end, {
        description = "swap with left client",
        group = "client"
    }), awful.key({ modkey, "Control" }, "l", function(c)
        awful.client.swap.global_bydirection("right")
        c:raise()
    end, {
        description = "swap with right client",
        group = "client"
    }), awful.key({ modkey, "Control" }, "j", function(c)
        awful.client.swap.global_bydirection("down")
        c:raise()
    end, {
        description = "swap with down client",
        group = "client"
    }), awful.key({ modkey, "Control" }, "k", function(c)
        awful.client.swap.global_bydirection("up")
        c:raise()
    end, {
        description = "swap with up client",
        group = "client"
    }), -- Handling window states
    awful.key({ modkey }, "w", function(c)
        c:kill()
    end, {
        description = "close",
        group = "client"
    }), awful.key({ modkey }, "f", awful.client.floating.toggle, {
        description = "toggle floating",
        group = "client"
    }), awful.key({ modkey, "Shift" }, "f", function(c)
        c.fullscreen = not c.fullscreen
        c:raise()
    end, {
        description = "toggle fullscreen",
        group = "client"
    }), awful.key({ modkey }, "u", awful.client.urgent.jumpto, {
        description = "jump to urgent client",
        group = "client"
    }), awful.key({ modkey }, "y", function(c)
        c:move_to_screen()
    end, {
        description = "move to screen",
        group = "client"
    }))

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it work on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
    globalkeys = gears.table.join(globalkeys, -- View tag only.
        awful.key({ modkey }, "#" .. i + 9, function()
            local screen = awful.screen.focused()
            local tag = screen.tags[i]
            if tag then
                tag:view_only()
            end
        end, {
            description = "view tag #" .. i,
            group = "tag"
        }), -- Toggle tag display.
        awful.key({ modkey, "Control" }, "#" .. i + 9, function()
            local screen = awful.screen.focused()
            local tag = screen.tags[i]
            if tag then
                awful.tag.viewtoggle(tag)
            end
        end, {
            description = "toggle tag #" .. i,
            group = "tag"
        }), -- Move client to tag.
        awful.key({ modkey, "Shift" }, "#" .. i + 9, function()
            if client.focus then
                local tag = client.focus.screen.tags[i]
                if tag then
                    client.focus:move_to_tag(tag)
                end
            end
        end, {
            description = "move focused client to tag #" .. i,
            group = "tag"
        }), -- Toggle tag on focused client.
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9, function()
            if client.focus then
                local tag = client.focus.screen.tags[i]
                if tag then
                    client.focus:toggle_tag(tag)
                end
            end
        end, {
            description = "toggle focused client on tag #" .. i,
            group = "tag"
        }))
end

local clientbuttons = gears.table.join(awful.button({}, 1, function(c)
    c:emit_signal("request::activate", "mouse_click", {
        raise = true
    })
end), awful.button({ modkey }, 1, function(c)
    c:emit_signal("request::activate", "mouse_click", {
        raise = true
    })
    awful.mouse.client.move(c)
end), awful.button({ modkey }, 3, function(c)
    c:emit_signal("request::activate", "mouse_click", {
        raise = true
    })
    awful.mouse.client.resize(c)
end) -- awful.button({modkey}, 4, function(c)
--     awful.client.floating.toggle(c)
-- end),
-- awful.button({modkey}, 5, function(c)
--     awful.client.floating.toggle(c)
-- end)
)

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
-- Rules to apply to new clients (through the "manage" signal).
awful.rules.rules = { -- All clients will match this rule.
    {
        rule = {},
        properties = {
            border_width = beautiful.border_width,
            border_color = beautiful.border_normal,
            focus = awful.client.focus.filter,
            raise = true,
            keys = clientkeys,
            buttons = clientbuttons,
            screen = awful.screen.preferred,
            placement = awful.placement.centered
        }
    }, -- Floating clients.
    {
        rule_any = {
            instance = { "DTA",                                                     -- Firefox addon DownThemAll.
                "copyq",                                                            -- Includes session name in class.
                "pinentry" },
            class = { "Arandr", "Blueman-manager", "Gpick", "Kruler", "MessageWin", -- kalarm.
                "Sxiv", "Tor Browser",                                              -- Needs a fixed window size to avoid fingerprinting by screen size.
                "Wpa_gui", "veromix", "xtightvncviewer" },

            -- Note that the name property shown in xprop might be set slightly after creation of the client
            -- and the name shown there might not match defined rules here.
            name = { "Event Tester" -- xev.
            },
            role = { "AlarmWindow", -- Thunderbird's calendar.
                "ConfigManager",    -- Thunderbird's about:config.
                "pop-up"            -- e.g. Google Chrome's (detached) Developer Tools.
            }
        },
        properties = {
            floating = true
        }
    }, -- WhatsApp Web
    {
        rule = {
            instance = "crx_hnpfjngllnobngcgfapefoaidbinmjnm"
        },
        properties = {
            floating = false,
            maximized = false
        }
    }, -- Titlebars to normal clients and dialogs
    {
        rule_any = {
            type = { "normal", "dialog" }
        },
        properties = {
            titlebars_enabled = false
        }
    } -- Set Firefox to always map on the tag named "2" on screen 1.
    -- { rule = { class = "Firefox" },
    --   properties = { screen = 1, tag = "2" } },
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function(c)
    -- Set the windows at the slave,
    -- i.e. put it at the end of others instead of setting it master.
    if not awesome.startup then
        awful.client.setslave(c)
    end

    if awesome.startup and not c.size_hints.user_position and not c.size_hints.program_position then
        -- Prevent clients from being unreachable after screen count changes.
        awful.placement.no_offscreen(c)
    end
end)

-- Add a titlebar if titlebars_enabled is set to true in the rules.
client.connect_signal("request::titlebars", function(c)
    -- buttons for the titlebar
    local buttons = gears.table.join(awful.button({}, 1, function()
        c:emit_signal("request::activate", "titlebar", {
            raise = true
        })
        awful.mouse.client.move(c)
    end), awful.button({}, 3, function()
        c:emit_signal("request::activate", "titlebar", {
            raise = true
        })
        awful.mouse.client.resize(c)
    end))

    awful.titlebar(c):setup({
        { -- Left
            awful.titlebar.widget.iconwidget(c),
            buttons = buttons,
            layout = wibox.layout.fixed.horizontal
        },
        {     -- Middle
            { -- Title
                align = "center",
                widget = awful.titlebar.widget.titlewidget(c)
            },
            buttons = buttons,
            layout = wibox.layout.flex.horizontal
        },
        { -- Right
            awful.titlebar.widget.floatingbutton(c),
            awful.titlebar.widget.maximizedbutton(c),
            awful.titlebar.widget.stickybutton(c),
            awful.titlebar.widget.ontopbutton(c),
            awful.titlebar.widget.closebutton(c),
            layout = wibox.layout.fixed.horizontal()
        },
        layout = wibox.layout.align.horizontal
    })
end)

-- Enable sloppy focus, so that focus follows mouse.
client.connect_signal("mouse::enter", function(c)
    c:emit_signal("request::activate", "mouse_enter", {
        raise = false
    })
end)

client.connect_signal("focus", function(c)
    c.border_color = beautiful.border_focus
end)
client.connect_signal("unfocus", function(c)
    c.border_color = beautiful.border_normal
end)
-- }}}

-- Set notification timeout
naughty.config.defaults.timeout = 2

-- Set notification icon size
naughty.config.defaults.icon_size = 100

-- Floating windows always stay on top
client.connect_signal("property::floating", function(c)
    if not c.fullscreen then
        if c.floating then
            c.ontop = true
        else
            c.ontop = false
        end
    end
end)

-- {{ Auto-start
awful.spawn.with_shell(string.format("%s/.config/awesome/autostart.sh", os.getenv("HOME")))
-- }}
