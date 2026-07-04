local bind = require("lib.binds")
local commands = require("lib.commands")
local smw = require("modules.plugins")

local osd = commands.scripts_cmd.swayosd_focused

bind.exec_many({
  { keys = "SUPER + RETURN", desc = "Open terminal", command = commands.apps.terminal },
  { keys = "SUPER + F", desc = "Open file manager", command = commands.apps.file_manager },
  { keys = "SUPER + B", desc = "Open browser", command = commands.apps.browser },
  { keys = "SUPER + M", desc = "Open music player", command = commands.scripts_cmd.launch_or_focus .. " spotify-launcher" },
  { keys = "SUPER + G", desc = "Open WhatsApp", command = commands.webapp .. "=\"https://web.whatsapp.com/\"" },
  { keys = "SUPER + D", desc = "Open Discord", command = commands.apps.discord },
  { keys = "SUPER + SPACE", desc = "Launch apps", command = commands.launcher },
  { keys = "SUPER + Q", desc = "Power menu", command = commands.scripts_cmd.power_menu },
})

bind.exec_many({
  { keys = "SUPER + COMMA", desc = "Dismiss last notification", command = "makoctl dismiss" },
  { keys = "SUPER + SHIFT + COMMA", desc = "Dismiss all notifications", command = "makoctl dismiss --all" },
  {
    keys = "SUPER + CTRL + COMMA",
    desc = "Toggle silencing notifications",
    command = "makoctl mode -t do-not-disturb && makoctl mode | grep -q 'do-not-disturb' && notify-send \"Silenced notifications\" || notify-send \"Enabled notifications\"",
  },
  { keys = "SUPER + CTRL + N", desc = "Toggle nightlight", command = commands.scripts_cmd.toggle_nightlight },
  { keys = "SUPER + CTRL + R", desc = "Restart environment", command = commands.scripts_cmd.restart_environment },
  { keys = "PRINT", desc = "Screenshot of region", command = commands.scripts_cmd.screenshot },
  { keys = "SHIFT + PRINT", desc = "Screenshot of window", command = commands.scripts_cmd.screenshot .. " window" },
  { keys = "CTRL + PRINT", desc = "Screenshot of display", command = commands.scripts_cmd.screenshot .. " output" },
  { keys = "SUPER + PRINT", desc = "Color picker", command = "pkill hyprpicker || hyprpicker -a" },
})

bind.dispatch("SUPER + C", "Close active window", hl.dsp.window.close())
bind.dispatch("SUPER + V", "Toggle floating", hl.dsp.window.float({ action = "toggle" }))
bind.dispatch("SUPER + mouse:274", "Toggle floating with mouse", hl.dsp.window.float({ action = "toggle" }), { mouse = true })

bind.directional("SUPER", "Move focus", function(direction)
  return hl.dsp.focus({ direction = direction })
end)

bind.directional("SUPER + CTRL", "Move window", function(direction)
  return hl.dsp.window.move({ direction = direction })
end)

local resize_delta = {
  l = { x = -60, y = 0 },
  r = { x = 60, y = 0 },
  u = { x = 0, y = -60 },
  d = { x = 0, y = 60 },
}

bind.directional("SUPER + SHIFT", "Resize window", function(direction)
  local delta = resize_delta[direction]
  return hl.dsp.window.resize({ x = delta.x, y = delta.y, relative = true })
end)

bind.workspace_numbers(smw)

bind.dispatch("SUPER + mouse:272", "Move window", hl.dsp.window.drag(), { mouse = true })
bind.dispatch("SUPER + mouse:273", "Resize window", hl.dsp.window.resize(), { mouse = true })

bind.exec_many({
  { keys = "XF86AudioRaiseVolume", desc = "Volume up", command = osd .. " --output-volume raise" },
  { keys = "XF86AudioLowerVolume", desc = "Volume down", command = osd .. " --output-volume lower" },
  { keys = "XF86AudioMute", desc = "Mute", command = osd .. " --output-volume mute-toggle" },
  { keys = "XF86AudioMicMute", desc = "Mute microphone", command = osd .. " --input-volume mute-toggle" },
  { keys = "XF86MonBrightnessUp", desc = "Brightness up", command = osd .. " --brightness raise" },
  { keys = "XF86MonBrightnessDown", desc = "Brightness down", command = osd .. " --brightness lower" },
}, { locked = true, repeating = true })

bind.exec_many({
  { keys = "ALT + XF86AudioRaiseVolume", desc = "Volume up precise", command = osd .. " --output-volume +1" },
  { keys = "ALT + XF86AudioLowerVolume", desc = "Volume down precise", command = osd .. " --output-volume -1" },
  { keys = "ALT + XF86MonBrightnessUp", desc = "Brightness up precise", command = osd .. " --brightness +1" },
  { keys = "ALT + XF86MonBrightnessDown", desc = "Brightness down precise", command = osd .. " --brightness -1" },
}, { locked = true, repeating = true })

bind.exec_many({
  { keys = "XF86AudioNext", desc = "Next track", command = osd .. " --playerctl next" },
  { keys = "XF86AudioPause", desc = "Pause", command = osd .. " --playerctl play-pause" },
  { keys = "XF86AudioPlay", desc = "Play", command = osd .. " --playerctl play-pause" },
  { keys = "XF86AudioPrev", desc = "Previous track", command = osd .. " --playerctl previous" },
}, { locked = true })

hl.gesture({
  fingers = 3,
  direction = "horizontal",
  action = "workspace",
})
