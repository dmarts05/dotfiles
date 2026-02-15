local awful = require("awful")
local beautiful = require("beautiful")
local gears = require("gears")
local clientbuttons = require("bindings")
local config = require("config")

awful.rules.rules = {
    { rule = {},
      properties = {
          border_width = beautiful.border_width,
          border_color = beautiful.border_normal,
          focus = awful.client.focus.filter,
          raise = true,
          keys = gears.table.join(
              awful.key({ config.modkey }, "f", function(c) c.fullscreen = not c.fullscreen; c:raise() end),
              awful.key({ config.modkey }, "c", function(c) c:kill() end),
              awful.key({ config.modkey }, "v", awful.client.floating.toggle),
              awful.key({ config.modkey }, "y", function(c) c:move_to_screen() end)
          ),
          buttons = clientbuttons,
          screen = awful.screen.preferred,
          placement = awful.placement.no_overlap+awful.placement.no_offscreen,
          floating = false,
          maximized = false,
          maximized_horizontal = false,
          maximized_vertical = false,
      }
    },
    { rule_any = {
        class = { 
            "Arandr", "Blueman-manager", "Gpick", "Kruler", "MessageWin", 
            "Sxiv", "Wpa_gui", "veromix", "xtightvncviewer",
            "blueberry" 
        },
        name = { "Event Tester" },
        role = { "AlarmWindow", "ConfigManager", "pop-up", "GtkFileChooserDialog", "conversation" },
        type = { "dialog" }
      }, properties = { floating = true, placement = awful.placement.centered }
    },
    { rule = { name = "Picture-in-Picture" },
      properties = { floating = true, sticky = true, ontop = true },
      callback = function(c)
          c:geometry({ width = 600, height = 338 })
          awful.placement.bottom_right(c, { margins = { bottom = 40, right = 40 } })
      end
    },
    { rule = { class = "Steam", name = "Friends List" }, properties = { floating = true, width = 460, height = 800 } },
}

awful.layout.layouts = {
    awful.layout.suit.tile.right,
}

require("awful.autofocus")