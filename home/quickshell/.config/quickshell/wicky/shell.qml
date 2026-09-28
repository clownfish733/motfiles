import Quickshell

// A one-shot picker: it draws the strip, sets the wallpaper you choose, and
// exits. There is no daemon to keep running, so bind it straight to a key.
//
//   bind = SUPER, W, exec, qs -c wallpaper
ShellRoot {
    Picker {}
}
