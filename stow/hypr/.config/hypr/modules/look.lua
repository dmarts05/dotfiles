hl.config({
  general = {
    gaps_in = 5,
    gaps_out = 10,
    border_size = 2,
    col = {
      active_border = {
        colors = { "rgba(33ccffee)", "rgba(00ff99ee)" },
        angle = 45,
      },
      inactive_border = "rgba(595959aa)",
    },
    resize_on_border = false,
    allow_tearing = false,
    layout = "master",
  },
  decoration = {
    rounding = 0,
    shadow = {
      enabled = true,
      range = 2,
      render_power = 3,
      color = "rgba(1a1a1aee)",
    },
    blur = {
      enabled = false,
      size = 3,
      passes = 1,
      vibrancy = 0.1696,
    },
  },
  animations = {
    enabled = true,
  },
  dwindle = {
    preserve_split = true,
    force_split = 2,
  },
  master = {
    new_status = "slave",
    mfact = 0.5,
  },
  misc = {
    disable_hyprland_logo = true,
    disable_splash_rendering = true,
    focus_on_activate = true,
  },
})

hl.config({
  general = {
    col = {
      active_border = "rgb(a89984)",
    },
  },
})

local curves = {
  easeOutQuint = { { 0.23, 1 }, { 0.32, 1 } },
  easeInOutCubic = { { 0.65, 0.05 }, { 0.36, 1 } },
  linear = { { 0, 0 }, { 1, 1 } },
  almostLinear = { { 0.5, 0.5 }, { 0.75, 1.0 } },
  quick = { { 0.15, 0 }, { 0.1, 1 } },
}

for name, points in pairs(curves) do
  hl.curve(name, { type = "bezier", points = points })
end

local animations = {
  { leaf = "global", speed = 10, bezier = "default" },
  { leaf = "border", speed = 5.39, bezier = "easeOutQuint" },
  { leaf = "windows", speed = 4.79, bezier = "easeOutQuint" },
  { leaf = "windowsIn", speed = 4.1, bezier = "easeOutQuint", style = "popin 87%" },
  { leaf = "windowsOut", speed = 1.49, bezier = "linear", style = "popin 87%" },
  { leaf = "windowsMove", speed = 4, bezier = "easeOutQuint" },
  { leaf = "fadeIn", speed = 1.73, bezier = "almostLinear" },
  { leaf = "fadeOut", speed = 1.46, bezier = "almostLinear" },
  { leaf = "fade", speed = 3.03, bezier = "quick" },
  { leaf = "layers", speed = 3.81, bezier = "easeOutQuint" },
  { leaf = "layersIn", speed = 4, bezier = "easeOutQuint", style = "fade" },
  { leaf = "layersOut", speed = 1.5, bezier = "linear", style = "fade" },
  { leaf = "fadeLayersIn", speed = 1.79, bezier = "almostLinear" },
  { leaf = "fadeLayersOut", speed = 1.39, bezier = "almostLinear" },
  { leaf = "workspaces", speed = 4, bezier = "easeOutQuint", style = "slide" },
}

for _, animation in ipairs(animations) do
  animation.enabled = true
  hl.animation(animation)
end
