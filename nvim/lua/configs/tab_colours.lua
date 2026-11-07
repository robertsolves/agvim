-- The tabs along the top and bottom name themselves in the theme's 16 terminal
-- colours (lib/colours). This hands tmux the colours of the theme Neovim loaded,
-- whichever it is, when Neovim starts and when the theme changes.
if not vim.env.TMUX or vim.g.diff_only then
  return
end

local function colours()
  local out = {}
  for n = 0, 15 do
    out[n + 1] = vim.g["terminal_color_" .. n]
  end
  if #vim.tbl_keys(out) == 16 then
    return out
  end
  -- NvChad's themes always have these, even where terminal colours aren't set.
  local ok, base46 = pcall(require, "base46")
  if not ok then
    return nil
  end
  local t = base46.get_theme_tb "base_30"
  local function pick(...)
    for _, k in ipairs { ... } do
      if t[k] then
        return t[k]
      end
    end
  end
  return {
    pick("one_bg3", "black2"), pick "red", pick "green", pick "yellow", pick "blue", pick("purple", "dark_purple"),
    pick("cyan", "teal"), pick("light_grey", "white"), pick("grey", "grey_fg"), pick("pink", "baby_pink", "red"),
    pick("vibrant_green", "green"), pick("sun", "yellow"), pick("nord_blue", "blue"), pick("dark_purple", "purple"),
    pick("teal", "cyan"), pick "white",
  }
end

local function push()
  local list = colours()
  if not list or #list ~= 16 then
    return
  end
  local cmd = { vim.fn.expand "~/.local/bin/agvim", "_colours", "theme" }
  vim.list_extend(cmd, list)
  vim.system(cmd)
end

local group = vim.api.nvim_create_augroup("AgvimTabColours", { clear = true })
local function soon()
  vim.defer_fn(push, 200)
end
vim.api.nvim_create_autocmd({ "VimEnter", "ColorScheme" }, { group = group, callback = soon })
-- NvChad's theme picker (Space th) reloads base46 without a ColorScheme event.
vim.api.nvim_create_autocmd("User", { group = group, pattern = "NvThemeReload", callback = soon })
