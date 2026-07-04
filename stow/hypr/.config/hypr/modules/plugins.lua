local home = os.getenv("HOME") or "~"
local plugin_parent = home .. "/.config/hypr/plugins"

package.path = package.path
  .. ";"
  .. plugin_parent
  .. "/?.lua;"
  .. plugin_parent
  .. "/?/init.lua"

for _, module in ipairs({
  "split-monitor-workspaces",
  "globals",
  "helpers",
  "monitors",
  "dispatchers",
  "plugins.split-monitor-workspaces",
  "plugins.split-monitor-workspaces.init",
  "plugins.split-monitor-workspaces.lua.split-monitor-workspaces",
  "plugins.split-monitor-workspaces.lua.globals",
  "plugins.split-monitor-workspaces.lua.helpers",
  "plugins.split-monitor-workspaces.lua.monitors",
  "plugins.split-monitor-workspaces.lua.dispatchers",
}) do
  package.loaded[module] = nil
end

local hypr_require = require
require = __require
local smw = require("plugins.split-monitor-workspaces")
require = hypr_require

smw.setup({
  workspace_count = 9,
  keep_focused = false,
  enable_notifications = false,
  enable_persistent_workspaces = true,
})

return smw
