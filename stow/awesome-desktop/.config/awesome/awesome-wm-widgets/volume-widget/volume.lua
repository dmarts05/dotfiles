local awful     = require("awful")
local wibox     = require("wibox")
local spawn     = require("awful.spawn")
local gears     = require("gears")
local beautiful = require("beautiful")
local watch     = require("awful.widget.watch")
local utils     = require("awesome-wm-widgets.volume-widget.utils")

-- Helper: run spawn.easy_async under pcall
local function safe_spawn(cmd, callback)
    pcall(function()
        spawn.easy_async(cmd, callback or function() end)
    end)
end

-- List all sinks and sources via pactl
local LIST_DEVICES_CMD = [[sh -c "pactl list sinks; pactl list sources"]]

-- Build pactl commands
local function GET_VOLUME_CMD(device_type)
    if device_type == "sink" then
        return [[sh -c "pactl get-sink-volume @DEFAULT_SINK@; pactl get-sink-mute @DEFAULT_SINK@"]]
    else
        return [[sh -c "pactl get-source-volume @DEFAULT_SOURCE@; pactl get-source-mute @DEFAULT_SOURCE@"]]
    end
end

local function INC_VOLUME_CMD(device_type, step)
    if device_type == "sink" then
        return "pactl set-sink-volume @DEFAULT_SINK@ +" .. step .. "%"
    else
        return "pactl set-source-volume @DEFAULT_SOURCE@ +" .. step .. "%"
    end
end

local function DEC_VOLUME_CMD(device_type, step)
    if device_type == "sink" then
        return "pactl set-sink-volume @DEFAULT_SINK@ -" .. step .. "%"
    else
        return "pactl set-source-volume @DEFAULT_SOURCE@ -" .. step .. "%"
    end
end

local function TOG_VOLUME_CMD(device_type)
    if device_type == "sink" then
        return "pactl set-sink-mute @DEFAULT_SINK@ toggle"
    else
        return "pactl set-source-mute @DEFAULT_SOURCE@ toggle"
    end
end

-- Available widget-types
local widget_types = {
    icon_and_text  = require("awesome-wm-widgets.volume-widget.widgets.icon-and-text-widget"),
    icon           = require("awesome-wm-widgets.volume-widget.widgets.icon-widget"),
    arc            = require("awesome-wm-widgets.volume-widget.widgets.arc-widget"),
    horizontal_bar = require("awesome-wm-widgets.volume-widget.widgets.horizontal-bar-widget"),
    vertical_bar   = require("awesome-wm-widgets.volume-widget.widgets.vertical-bar-widget"),
}

local volume       = {}
local rows         = { layout = wibox.layout.fixed.vertical }

-- Popup for sinks/sources
local popup        = awful.popup({
    bg            = beautiful.bg_normal,
    fg            = beautiful.fg_normal,
    ontop         = true,
    visible       = false,
    shape         = gears.shape.rounded_rect,
    border_width  = 1,
    border_color  = beautiful.bg_focus,
    maximum_width = 400,
    offset        = { y = 5 },
    widget        = {},
})

local function build_main_line(device)
    if device.active_port and device.ports[device.active_port] then
        return device.properties.device_description
            .. " · "
            .. device.ports[device.active_port]
    else
        return device.properties.device_description
    end
end

local function build_rows(devices, on_click, device_type)
    local device_rows = { layout = wibox.layout.fixed.vertical }
    for _, dev in ipairs(devices) do
        local checkbox = wibox.widget {
            checked       = dev.is_default,
            color         = beautiful.fg_normal,
            paddings      = 2,
            shape         = gears.shape.circle,
            forced_width  = 20,
            forced_height = 20,
            check_color   = beautiful.fg_normal,
            widget        = wibox.widget.checkbox,
        }

        local function set_default()
            safe_spawn(
                string.format([[sh -c 'pactl set-default-%s "%s"']], device_type, dev.name),
                on_click
            )
        end

        checkbox:connect_signal("button::press", set_default)

        local row = wibox.widget {
            {
                {
                    {
                        checkbox,
                        valign = "center",
                        layout = wibox.container.place,
                    },
                    {
                        {
                            text   = build_main_line(dev),
                            align  = "left",
                            widget = wibox.widget.textbox,
                        },
                        left   = 10,
                        layout = wibox.container.margin,
                    },
                    spacing = 8,
                    layout  = wibox.layout.align.horizontal,
                },
                margins = 4,
                layout  = wibox.container.margin,
            },
            bg     = beautiful.bg_normal,
            fg     = beautiful.fg_normal,
            widget = wibox.container.background,
        }

        -- hover/click effects
        row:connect_signal("mouse::enter", function(c)
            checkbox:set_color(beautiful.fg_focus)
            checkbox:set_check_color(beautiful.fg_focus)
            c:set_fg(beautiful.fg_focus)
            c:set_bg(beautiful.bg_focus)
        end)
        row:connect_signal("mouse::leave", function(c)
            checkbox:set_color(beautiful.fg_normal)
            checkbox:set_check_color(beautiful.fg_normal)
            c:set_fg(beautiful.fg_normal)
            c:set_bg(beautiful.bg_normal)
        end)
        row:connect_signal("button::press", set_default)
        row:connect_signal("mouse::enter", function()
            local wb = mouse.current_wibox
            if wb then wb.cursor = "hand1" end
        end)
        row:connect_signal("mouse::leave", function()
            local wb = mouse.current_wibox
            if wb then wb.cursor = nil end
        end)

        table.insert(device_rows, row)
    end
    return device_rows
end

local function build_header_row(title)
    return wibox.widget {
        {
            markup = "<b>" .. title .. "</b>",
            align  = "center",
            widget = wibox.widget.textbox,
        },
        bg     = beautiful.bg_normal,
        fg     = beautiful.fg_normal,
        widget = wibox.container.background,
    }
end

local function rebuild_popup()
    safe_spawn(LIST_DEVICES_CMD, function(stdout)
        local sinks, sources = utils.extract_sinks_and_sources(stdout)
        for i = 1, #rows do rows[i] = nil end
        table.insert(rows, build_header_row("SINKS"))
        table.insert(rows, build_rows(sinks, rebuild_popup, "sink"))
        table.insert(rows, build_header_row("SOURCES"))
        table.insert(rows, build_rows(sources, rebuild_popup, "source"))
        popup:setup(rows)
    end)
end

local function worker(user_args)
    local args         = user_args or {}
    local mixer_cmd    = args.mixer_cmd or "pavucontrol"
    local widget_type  = args.widget_type or "icon_and_text"
    local refresh_rate = args.refresh_rate or 0.1
    local step         = args.step or 5
    local device_type  = args.device_type or "sink"

    -- pick widget
    local wt           = widget_types[widget_type]
    volume.widget      = wt and wt.get_widget(args)
        or widget_types.icon_and_text.get_widget(args)

    -- parse pactl output into widget
    local function update_graphic(widget, stdout)
        -- volume%
        local vol = stdout:match("(%d?%d?%d)%%")
        if vol and widget.set_volume_level then
            widget:set_volume_level(string.format("%3d", vol))
        end

        -- mute state
        local is_mute = stdout:match("Mute:%s+yes")
        if is_mute then
            if widget.mute then pcall(widget.mute, widget) end
        else
            if widget.unmute then pcall(widget.unmute, widget) end
        end
    end

    -- controls
    function volume:inc(s)
        safe_spawn(INC_VOLUME_CMD(device_type, s or step), function()
            safe_spawn(GET_VOLUME_CMD(device_type), update_graphic)
        end)
    end

    function volume:dec(s)
        safe_spawn(DEC_VOLUME_CMD(device_type, s or step), function()
            safe_spawn(GET_VOLUME_CMD(device_type), update_graphic)
        end)
    end

    function volume:toggle()
        safe_spawn(TOG_VOLUME_CMD(device_type), function()
            safe_spawn(GET_VOLUME_CMD(device_type), update_graphic)
        end)
    end

    function volume:mixer()
        if mixer_cmd then
            pcall(function() spawn.easy_async(mixer_cmd) end)
        end
    end

    -- mouse bindings
    volume.widget:buttons(awful.util.table.join(
        awful.button({}, 3, function()
            if popup.visible then
                popup.visible = false
            else
                rebuild_popup()
                popup:move_next_to(mouse.current_widget_geometry)
            end
        end),
        awful.button({}, 4, function() volume:inc() end),
        awful.button({}, 5, function() volume:dec() end),
        awful.button({}, 2, function() volume:mixer() end),
        awful.button({}, 1, function() volume:toggle() end)
    ))

    -- start watching, wrapped in pcall
    pcall(function()
        watch(
            GET_VOLUME_CMD(device_type),
            refresh_rate,
            update_graphic,
            volume.widget
        )
    end)

    return volume.widget
end

return setmetatable(volume, {
    __call = function(_, ...) return worker(...) end
})
