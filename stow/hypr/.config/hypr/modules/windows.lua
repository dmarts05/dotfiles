local rules = require("lib.rules")

rules.windows({
  {
    name = "fix-xwayland-drags",
    match = {
      class = "^$",
      title = "^$",
      xwayland = true,
      float = true,
      fullscreen = false,
      pin = false,
    },
    no_focus = true,
  },
  {
    name = "tag-terminals",
    match = { class = "(Alacritty|kitty|com.mitchellh.ghostty|foot)" },
    tag = "+terminal",
  },
  {
    name = "tag-pip",
    match = { title = "(Picture.?in.?[Pp]icture)" },
    tag = "+pip",
  },
  {
    name = "style-pip",
    match = { tag = "pip" },
    float = true,
    pin = true,
    size = "600 338",
    keep_aspect_ratio = true,
    border_size = 0,
    move = "((monitor_w*1)-window_w-40) ((monitor_h*0.04))",
  },
  {
    name = "steam-friends",
    match = { class = "steam", title = "Friends List" },
    float = true,
    center = true,
    size = "460 800",
  },
  {
    name = "jetbrains-popup-size",
    match = { class = "(.*jetbrains.*)$", title = "^$", float = true },
    size = "(monitor_w*0.5) (monitor_h*0.5)",
  },
  {
    name = "jetbrains-tab-drag",
    match = { class = "^(.*jetbrains.*)$", title = "^\\s$" },
    no_initial_focus = true,
    no_focus = true,
  },
  {
    name = "style-floating-window-tag",
    match = { tag = "floating-window" },
    float = true,
    center = true,
    size = "800 600",
  },
  {
    name = "tag-floating-tools",
    match = { class = "(blueberry.py|Impala|Wiremix|org.gnome.NautilusPreviewer|com.gabm.satty|About|TUI.float)" },
    tag = "+floating-window",
  },
  {
    name = "tag-floating-file-dialogs",
    match = {
      class = "(xdg-desktop-portal-gtk|sublime_text|DesktopEditors|org.gnome.Nautilus|helium)",
      title = "^(Open.*Files?|Open [F|f]older.*|Save.*Files?|Save.*As|Save|All Files)",
    },
    tag = "+floating-window",
  },
  {
    name = "tag-helium-save-dialog",
    match = { class = "helium", title = ".*wants to save.*" },
    tag = "+floating-window",
  },
  {
    name = "tag-modal-dialogs",
    match = { modal = true },
    tag = "+floating-window",
  },
  {
    name = "style-thunar-dialog",
    match = { tag = "thunar-dialog" },
    float = true,
    center = true,
    size = "400 100",
  },
  {
    name = "tag-thunar-dialog",
    match = {
      class = "thunar",
      title = "^(File Operation Progress|Rename|Confirm|Move to Trash|Replace|Error|Failed).*$",
    },
    tag = "+thunar-dialog",
  },
  {
    name = "screensaver-fullscreen",
    match = { class = "Screensaver" },
    fullscreen = true,
  },
})

rules.layer({
  name = "hyprshot-selection-no-anim",
  match = { namespace = "selection" },
  no_anim = true,
})
