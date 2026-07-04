hl.config({
  input = {
    kb_layout = "es",
    repeat_rate = 40,
    repeat_delay = 210,
    sensitivity = 0,
    accel_profile = "flat",
    numlock_by_default = true,
    follow_mouse = 1,
    touchpad = {
      natural_scroll = true,
      clickfinger_behavior = true,
      scroll_factor = 0.4,
      disable_while_typing = true,
      tap_to_click = true,
    },
  },
})

hl.device({
  name = "sino-wealth-peripad-506-touchpad",
  sensitivity = 0.4,
})

hl.window_rule({
  name = "terminal-touchpad-scroll",
  match = { tag = "terminal" },
  scroll_touchpad = 1.5,
})
