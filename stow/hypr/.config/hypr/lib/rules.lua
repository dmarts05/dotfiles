local M = {}

function M.window(spec)
  return hl.window_rule(spec)
end

function M.layer(spec)
  return hl.layer_rule(spec)
end

function M.windows(specs)
  for _, spec in ipairs(specs) do
    M.window(spec)
  end
end

function M.layers(specs)
  for _, spec in ipairs(specs) do
    M.layer(spec)
  end
end

return M
