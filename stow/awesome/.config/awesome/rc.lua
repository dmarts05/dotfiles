pcall(require, "luarocks.loader")
local gears = require("gears")
local beautiful = require("beautiful")

-- Initialize Theme
beautiful.init(gears.filesystem.get_configuration_dir() .. "theme.lua")

-- Load Modules
require("env")               -- Environment Variables
require("bindings")          -- Keys/Mouse Bindings
require("rules")             -- Rules & Layouts
require("ui.notifications")  -- UI Logic
require("ui.bar")            -- Bar & Widgets
require("signals")           -- Signals & Errors
require("autostart")         -- Autostart & Input setup