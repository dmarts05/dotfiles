local theme_assets = require("beautiful.theme_assets")
local gfs = require("gears.filesystem")
local themes_path = gfs.get_themes_dir()

local theme = dofile(themes_path .. "default/theme.lua")

theme.font = "CaskaydiaMono Nerd Font 10.0"

-- Gruvbox Material Colors
theme.bg_normal   = "#282828"
theme.fg_normal   = "#d4be98"
theme.bg_focus    = "#32302f"
theme.fg_focus    = "#d4be98"
theme.bg_urgent   = "#ea6962"
theme.fg_urgent   = "#282828"
theme.bg_minimize = "#1d2021"

theme.border_width  = 2
theme.border_normal = "#595959aa"
theme.border_focus  = "#a89984"
theme.border_radius = 0

-- Wibar
theme.wibar_bg = theme.bg_normal
theme.wibar_fg = theme.fg_normal

-- Systray
theme.systray_icon_spacing = 10
theme.bg_systray = theme.bg_normal

theme.useless_gap = 5
theme.gap_single_client = true

local config_dir = gfs.get_configuration_dir()
theme.wallpaper = config_dir .. "wallpaper.jpg"

theme.icon_theme = "Numix"
theme.awesome_icon = theme_assets.awesome_icon(24, theme.fg_normal, theme.bg_normal)

return theme