local glib = require("lgi").GLib

-- Session Type
glib.setenv("XDG_CURRENT_DESKTOP", "awesome", true)
glib.setenv("XDG_SESSION_DESKTOP", "awesome", true)
glib.setenv("XDG_SESSION_TYPE", "x11", true)

-- Force X11 Backends
glib.setenv("GDK_BACKEND", "x11", true)
glib.setenv("QT_QPA_PLATFORM", "xcb", true)
glib.setenv("SDL_VIDEODRIVER", "x11", true)

-- Qt Theming
glib.setenv("QT_QPA_PLATFORMTHEME", "qt6ct", true)
glib.setenv("QT_STYLE_OVERRIDE", "qt6ct", true)

-- Cursor Theme
glib.setenv("XCURSOR_THEME", "XCursor-Pro-Dark", true)
glib.setenv("XCURSOR_SIZE", "20", true)

-- Apps
glib.setenv("TERMINAL", "alacritty", true)
glib.setenv("EDITOR", "nvim", true)