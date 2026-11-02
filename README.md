# NeoVim Extension

## nvim-color-line-numbers-by-mode

A plugin for NeoVim to color the line numbers based on the current mode (Normal, Insert or Visual) to help you better see the mode you're in. The line colors correspond to the default mode colors of NeoVim.

## Installing with Lazy

```lua
return {
  {
    "dev-cetera/nvim-color-line-numbers-by-mode",
    lazy = false, --load during startup
    config = function()
      require("nvim-color-line-numbers-by-mode").setup()
    end,
  },
}
```

## Options

Pass your own colours to `setup`. Visual covers `v`, `V` and Ctrl-V. A mode set to `nil` keeps the theme's colour.

```lua
require("nvim-color-line-numbers-by-mode").setup({
  colors = { n = "#44a8e5", i = "#c177e5", v = "#88deff", R = "#e5a844" },
})
```
