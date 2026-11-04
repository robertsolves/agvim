-- This file needs to have same structure as nvconfig.lua
-- https://github.com/NvChad/ui/blob/v3.0/lua/nvconfig.lua
-- Please read that file to know all available options :(

---@type ChadrcConfig
local M = {}

M.base46 = {
  theme = "dark_horizon",

  -- Near-black, with silver for the active tab, the mode and the lines between windows.
  changed_themes = {
    dark_horizon = {
      base_16 = { base00 = "#0a0a0a" },
      base_30 = {
        black = "#0a0a0a",
        darker_black = "#050505",
        black2 = "#141416",
        one_bg = "#1c1c1f",
        one_bg2 = "#26272b",
        one_bg3 = "#303238",
        grey = "#5f646c",
        grey_fg = "#7f858e",
        grey_fg2 = "#9aa0a8",
        light_grey = "#b4b9c0",
        line = "#3a3d42",
        statusline_bg = "#1a1b1e",
        lightbg = "#34363b",
        white = "#e6e8eb",
      },
    },
  },

  hl_override = {
    TbBufOn = { fg = "#0a0a0a", bg = "#c8ccd2", bold = true },
    TbBufOnClose = { fg = "#b00020", bg = "#c8ccd2" },
    TbBufOnModified = { fg = "#0a7a2f", bg = "#c8ccd2" },
    TbBufOff = { fg = "#9aa0a8", bg = "#141416" },
    TbFill = { bg = "#141416" },
    WinSeparator = { fg = "#8d949e" },
    NvimTreeWinSeparator = { fg = "#8d949e", bg = "#0a0a0a" },
    NvimTreeNormal = { bg = "#141416" },
    NvimTreeNormalNC = { bg = "#141416" },
    NvimTreeRootFolder = { fg = "#c8ccd2", bold = true },
    LineNr = { fg = "#6b7078" },
    CursorLineNr = { fg = "#ffffff", bold = true },
    St_NormalMode = { fg = "#0a0a0a", bg = "#c8ccd2", bold = true },
    St_NormalModeSep = { fg = "#c8ccd2", bg = "#34363b" },
    St_file = { fg = "#e6e8eb", bg = "#34363b" },
    St_file_sep = { fg = "#34363b", bg = "#1a1b1e" },
    Comment = { fg = "#7f858e", italic = true },
    ["@comment"] = { fg = "#7f858e", italic = true },
  },
}

M.ui = {
  statusline = { theme = "default", separator_style = "default" },
}

return M
