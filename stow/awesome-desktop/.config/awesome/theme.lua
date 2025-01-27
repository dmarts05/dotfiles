local theme_assets = require("beautiful.theme_assets")
local gfs = require("gears.filesystem")
local themes_path = gfs.get_themes_dir()
local gears_shape = require("gears.shape")
local wibox = require("wibox")
local awful_widget_clienticon = require("awful.widget.clienticon")

-- inherit xresources theme:
local theme = dofile(themes_path .. "xresources/theme.lua")

theme.font = "NotoSans Nerd Font 11.0"

theme.bg_normal = "#1e1e2eff"
theme.fg_normal = "#1e1e2eff"

theme.wibar_bg = "#11111bff"
theme.wibar_fg = "#ffffffff"

theme.bg_focus = "#cba6f7ff"
theme.fg_focus = "#000000de"

theme.bg_urgent = "#f44336ff"
theme.fg_urgent = "#ffffffff"

theme.bg_minimize = "#595960"
theme.fg_minimize = "#e8e8e9"

theme.bg_systray = "#11111bff"

theme.border_normal = "#11111bff"
theme.border_focus = "#cba6f7ff"
theme.border_marked = "#66bb6aff"

theme.border_width = 2
theme.border_radius = 6

theme.useless_gap = 3

local rounded_rect_shape = function(cr, w, h)
    gears_shape.rounded_rect(cr, w, h, theme.border_radius)
end

theme.tasklist_fg_normal = "#ffffffff"
theme.tasklist_bg_normal = "#11111bff"
theme.tasklist_fg_focus = "#ffffffff"
theme.tasklist_bg_focus = "#11111bff"

theme.tasklist_font_focus = "NotoSans Nerd Font Bold 11.0"

theme.tasklist_shape_minimized = rounded_rect_shape
theme.tasklist_shape_border_color_minimized = "#6f6f75"
theme.tasklist_shape_border_width_minimized = 2

theme.tasklist_spacing = 2

theme.tasklist_widget_template = {
    {
        {
            {
                {
                    id = 'clienticon',
                    widget = awful_widget_clienticon
                },
                margins = 4,
                widget = wibox.container.margin
            },
            {
                id = 'text_role',
                widget = wibox.widget.textbox
            },
            layout = wibox.layout.fixed.horizontal
        },
        left = 2,
        right = 4,
        widget = wibox.container.margin
    },
    id = 'background_role',
    widget = wibox.container.background,
    create_callback = function(self, c)
        self:get_children_by_id('clienticon')[1].client = c
    end
}

theme.taglist_shape_container = rounded_rect_shape
theme.taglist_shape_clip_container = true
theme.taglist_shape_border_width_container = 4
theme.taglist_shape_border_color_container = "#ffffffb3"

theme.taglist_bg_occupied = "#11111bff"
theme.taglist_fg_occupied = "#ffffffff"

theme.taglist_bg_empty = "#11111b"
theme.taglist_fg_empty = "#88888d"

theme.titlebar_font_normal = "NotoSans Nerd Font Bold 11.0"
theme.titlebar_bg_normal = "#11111bff"
theme.titlebar_fg_normal = "#ffffffff"

theme.titlebar_font_focus = "NotoSans Nerd Font Bold 11.0"
theme.titlebar_bg_focus = "#cba6f7ff"
theme.titlebar_fg_focus = "#000000de"

theme.tooltip_fg = "#ffffffff"
theme.tooltip_bg = "#1e1e2eff"

theme.menu_border_width = 2
theme.menu_border_color = "#595960"
theme.menu_bg_normal = "#11111bff"
theme.menu_fg_normal = "#ffffffff"

theme.menu_height = 24
theme.menu_width = 150
theme.menu_submenu_icon = nil
theme.menu_submenu = "▸ "

theme.notification_fg = "#ffffffff"

-- Recolor Layout icons:
theme = theme_assets.recolor_layout(theme, theme.wibar_fg)

-- Recolor titlebar icons:
theme = theme_assets.recolor_titlebar(theme, "#ffffffff", "normal")
theme = theme_assets.recolor_titlebar(theme, "#cdcdcdff", "normal", "hover")
theme = theme_assets.recolor_titlebar(theme, "#f44336ff", "normal", "press")
theme = theme_assets.recolor_titlebar(theme, "#000000de", "focus")
theme = theme_assets.recolor_titlebar(theme, "#323232de", "focus", "hover")
theme = theme_assets.recolor_titlebar(theme, "#f44336ff", "focus", "press")

-- Define the icon theme for application icons. If not set then the icons
-- from /usr/share/icons and /usr/share/icons/hicolor will be used.
theme.icon_theme = nil

-- Generate Awesome icon:
theme.awesome_icon = theme_assets.awesome_icon(theme.menu_height, "#e5d3fb", theme.wibar_bg)

-- Generate taglist squares:
-- local taglist_square_size = 4
-- theme.taglist_squares_sel = theme_assets.taglist_squares_sel(taglist_square_size, "#ffffffb3")
-- theme.taglist_squares_unsel = theme_assets.taglist_squares_unsel(taglist_square_size, "#ffffffb3")
-- Or disable them:
theme.taglist_squares_sel = nil
theme.taglist_squares_unsel = nil

-- Set wallpaper
theme.wallpaper = string.format("%s/.config/awesome/wallpaper.png", os.getenv("HOME"))

return theme
