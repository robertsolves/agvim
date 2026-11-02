local function flutter(lhs, cmd, desc)
  vim.keymap.set("n", lhs, "<cmd>Flutter" .. cmd .. "<CR>", { buffer = true, desc = desc })
end

flutter("<Leader>Fr", "Run", "Flutter: run (debug)")
flutter("<Leader>Fh", "Reload", "Flutter: hot reload")
flutter("<Leader>FR", "Restart", "Flutter: hot restart")
flutter("<Leader>Fq", "Quit", "Flutter: quit")
flutter("<Leader>Fd", "Devices", "Flutter: devices")
flutter("<Leader>Fe", "Emulators", "Flutter: emulators")
flutter("<Leader>Fo", "OutlineToggle", "Flutter: widget outline")
flutter("<Leader>Fl", "LogToggle", "Flutter: log")
flutter("<Leader>Ft", "DevTools", "Flutter: DevTools")
flutter("<Leader>Fp", "PubGet", "Flutter: pub get")
