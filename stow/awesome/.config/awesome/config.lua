local beautiful = require("beautiful")

local _M = {}

_M.modkey = "Mod4"
_M.altkey = "Mod1"
_M.ctrlkey = "Control"
_M.shiftkey = "Shift"

local lock_color = beautiful.bg_normal:gsub("#", "")

_M.apps = {
    terminal = "alacritty",
    launcher = "rofi -show drun -theme ~/.config/rofi/config.rasi",
    browser = "helium-browser --new-window",
    file_manager = "thunar",
    music = "spotify-launcher",
    discord = "discord",
    whatsapp = "chromium --app=https://web.whatsapp.com/",
    screenshot = "flameshot gui",
    screenshot_full = "flameshot screen",
    lock = "i3lock -c " .. lock_color,
    bluetooth_manager = "blueberry"
}

return _M