local gears = require("gears")
local naughty = require("naughty")
local beautiful = require("beautiful")

-- Styling
naughty.config.defaults.position = "top_right"
naughty.config.padding = 26 
naughty.config.spacing = 13  
naughty.config.defaults.margin = 15      
naughty.config.defaults.border_width = 2 
naughty.config.defaults.shape = function(cr, w, h) gears.shape.rectangle(cr, w, h) end

naughty.config.presets.normal.border_color = beautiful.border_focus 
naughty.config.presets.normal.bg = beautiful.bg_normal          
naughty.config.presets.normal.fg = beautiful.fg_normal          

naughty.config.presets.critical.border_color = beautiful.bg_urgent 
naughty.config.presets.critical.bg = beautiful.bg_normal       
naughty.config.presets.critical.fg = beautiful.fg_urgent       

-- OSD Logic
local notification_id = nil

local function make_progress_bar(percent)
    local length = 15
    local filled = math.floor(percent / 100 * length)
    local bar = ""
    for i = 1, length do
        if i <= filled then bar = bar .. "█" else bar = bar .. "░" end
    end
    return bar
end

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
        width = 250,
    })
end

return {
    notify_osd = notify_osd
}