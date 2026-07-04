local home = os.getenv("HOME") or "~"
local hypr = home .. "/.config/hypr"
local scripts = hypr .. "/scripts"

local M = {
  hypr = hypr,
  scripts = scripts,
  run = "runapp",
}

function M.runapp(command)
  return M.run .. " " .. command
end

M.apps = {
  terminal = M.runapp("footclient"),
  browser = M.runapp("helium-browser --new-window --ozone-platform=wayland --disable-features=WaylandWpColorManagerV1"),
  file_manager = M.runapp("thunar"),
  discord = M.runapp("discord"),
  foot_server = M.runapp("foot --server"),
  hypridle = M.runapp("hypridle"),
  mako = M.runapp("mako"),
  waybar = M.runapp("waybar"),
  swayosd = M.runapp("swayosd-server"),
  wallpaper = M.runapp("swaybg -i " .. hypr .. "/wallpaper.jpg -m fill"),
  polkit = "/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1",
  clip_persist = "wl-clip-persist --clipboard regular --all-mime-type-regex '^(?!x-kde-passwordManagerHint).+'",
}

M.scripts_cmd = {
  launch_or_focus = scripts .. "/launch-or-focus",
  lock_screen = scripts .. "/lock-screen",
  power_menu = scripts .. "/power-menu",
  restart_environment = scripts .. "/restart-environment",
  screenshot = scripts .. "/screenshot",
  swayosd_focused = scripts .. "/swayosd-focused",
  toggle_nightlight = scripts .. "/toggle-nightlight",
}

M.launcher = "sh -c 'tofi-drun --font /usr/share/fonts/TTF/CaskaydiaMonoNerdFont-Regular.ttf | xargs -r runapp'"
M.webapp = M.runapp("chromium --new-window --ozone-platform=wayland --disable-features=WaylandWpColorManagerV1 --app")

function M.hyprctl_dispatch(dispatcher, arg)
  if arg == nil or arg == "" then
    return "hyprctl dispatch " .. dispatcher
  end

  return "hyprctl dispatch " .. dispatcher .. " " .. tostring(arg)
end

return M
