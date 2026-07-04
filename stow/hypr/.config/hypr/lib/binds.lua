local commands = require("lib.commands")

local M = {}

local default_flags = {}

local function bind(keys, dispatcher, opts)
  return hl.bind(keys, dispatcher, opts or default_flags)
end

function M.exec(keys, description, command, opts)
  opts = opts or {}
  opts.desc = description
  opts.description = description
  return bind(keys, hl.dsp.exec_cmd(command), opts)
end

function M.dispatch(keys, description, dispatcher, opts)
  opts = opts or {}
  opts.desc = description
  opts.description = description
  return bind(keys, dispatcher, opts)
end

function M.exec_many(items, default_opts)
  for _, item in ipairs(items) do
    local opts = {}
    for key, value in pairs(default_opts or {}) do
      opts[key] = value
    end
    for key, value in pairs(item.opts or {}) do
      opts[key] = value
    end

    M.exec(item.keys, item.desc, item.command, opts)
  end
end

function M.dispatch_many(items, default_opts)
  for _, item in ipairs(items) do
    local opts = {}
    for key, value in pairs(default_opts or {}) do
      opts[key] = value
    end
    for key, value in pairs(item.opts or {}) do
      opts[key] = value
    end

    M.dispatch(item.keys, item.desc, item.dispatcher, opts)
  end
end

function M.directional(mods, action_name, dispatcher_factory)
  local keys = {
    { key = "left", dir = "l", label = "left" },
    { key = "right", dir = "r", label = "right" },
    { key = "up", dir = "u", label = "up" },
    { key = "down", dir = "d", label = "down" },
    { key = "H", dir = "l", label = "left (HJKL)" },
    { key = "L", dir = "r", label = "right (HJKL)" },
    { key = "K", dir = "u", label = "up (HJKL)" },
    { key = "J", dir = "d", label = "down (HJKL)" },
  }

  for _, item in ipairs(keys) do
    M.dispatch(mods .. " + " .. item.key, action_name .. " " .. item.label, dispatcher_factory(item.dir))
  end
end

function M.workspace_numbers(smw)
  for i = 1, 9 do
    local workspace = tostring(i)
    M.dispatch("SUPER + " .. i, "Switch to workspace " .. i, smw.workspace(workspace))
    M.dispatch("SUPER + SHIFT + " .. i, "Move window to workspace " .. i, smw.move_to_workspace_silent(workspace))
  end
end

return M
