local gears = require("gears")
local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local config = require("config")

-- Creates a widget with a tooltip, using a default icon
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

-- Volume
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

-- Battery
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

-- Network
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
    awful.button({ }, 1, function() awful.spawn(config.apps.terminal .. " -e nmtui") end)
))

-- Bluetooth
local bt_widget, bt_tooltip = create_widget_with_tooltip("󰂲")
awful.widget.watch("bash -c 'cat /sys/class/bluetooth/hci0/rfkill*/state 2>/dev/null'", 5, function(widget, stdout)
    local state = tonumber(stdout:match("(%d)"))
    if not state then
        awful.spawn.easy_async_with_shell("ls /sys/class/bluetooth/ | grep hci", function(ls_out)
            bt_widget.visible = (ls_out ~= "")
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
    awful.button({ }, 1, function() awful.spawn(config.apps.bluetooth_manager) end)
))

-- Clock
local mytextclock = wibox.widget.textclock(" %d/%m/%y %R ")

-- Taglist Buttons
local taglist_buttons = gears.table.join(
    awful.button({}, 1, function(t) t:view_only() end),
    awful.button({ config.modkey }, 1, function(t) if client.focus then client.focus:move_to_tag(t) end end),
    awful.button({}, 3, awful.tag.viewtoggle),
    awful.button({ config.modkey }, 3, function(t) if client.focus then client.focus:toggle_tag(t) end end),
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
        }
    }

    s.mywibox = awful.wibar({ position = "top", screen = s, height = 26 }) 

    s.mywibox:setup({
        layout = wibox.layout.align.horizontal,
        expand = "none", 
        -- Left
        {
            layout = wibox.layout.fixed.horizontal,
            s.mytaglist,
        },
        -- Center
        {
            layout = wibox.layout.fixed.horizontal,
            mytextclock,
        },
        -- Right
        {
            layout = wibox.layout.fixed.horizontal,
            {
                widget = wibox.container.margin,
                right = 7,
                {
                    widget = wibox.container.place,
                    valign = "center",
                    {
                        widget = wibox.container.constraint,
                        strategy = "max",
                        height = 14, 
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