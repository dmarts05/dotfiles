local M = {}

M.desktop = {
  env = {
    GDK_SCALE = "1",
  },
  monitors = {
    { output = "DP-2", mode = "1920x1080@165", position = "0x0", scale = 1 },
    { output = "DP-3", mode = "1920x1080@165", position = "1920x0", scale = 1 },
  },
}

M.laptop = {
  env = {
    GDK_SCALE = "2",
  },
  monitors = {
    { output = "", mode = "preferred", position = "auto", scale = "auto" },
  },
}

function M.apply(profile)
  for key, value in pairs(profile.env or {}) do
    hl.env(key, value)
  end

  for _, monitor in ipairs(profile.monitors or {}) do
    hl.monitor(monitor)
  end
end

return M
