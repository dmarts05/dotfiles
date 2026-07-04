local commands = require("lib.commands")

local startup = {
  commands.apps.hypridle,
  commands.apps.mako,
  commands.apps.waybar,
  commands.apps.wallpaper,
  commands.apps.swayosd,
  commands.apps.polkit,
  commands.apps.clip_persist,
  commands.apps.foot_server,
}

hl.on("hyprland.start", function()
  for _, command in ipairs(startup) do
    hl.exec_cmd(command)
  end
end)
