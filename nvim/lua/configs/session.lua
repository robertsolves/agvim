-- Keeps this Neovim's open files, splits and cursors in a session file for its
-- tmux pane, so a project that's closed or lost in a crash reopens Neovim as it
-- was (lib/project save copies the file, restore opens it with nvim -S).
local pane = vim.env.TMUX_PANE
-- Every tmux server numbers its panes from %0, so the file is also kept per server
-- (its socket and pid, as lib/project finds it): a test's Neovim, or one left from a
-- server that's gone, can't write over yours.
local socket, pid = (vim.env.TMUX or ""):match "^(.-),(%d+),"
if not pane or not socket or vim.g.diff_only then
  return
end

local dir = vim.fn.stdpath "state" .. "/agvim-sessions/" .. socket:gsub("[^%w]", "_") .. "-" .. pid
local file = dir .. "/" .. pane:gsub("%%", "") .. ".vim"

local function write()
  if vim.fn.getcmdwintype() ~= "" then
    return
  end
  vim.fn.mkdir(dir, "p")
  local old = vim.o.sessionoptions
  vim.opt.sessionoptions:remove { "terminal", "blank" }
  pcall(vim.cmd, "silent mksession! " .. vim.fn.fnameescape(file))
  vim.o.sessionoptions = old
end

-- A few seconds after things settle, not on every keystroke.
local timer = vim.uv.new_timer()
local function soon()
  timer:stop()
  timer:start(3000, 0, vim.schedule_wrap(write))
end

local group = vim.api.nvim_create_augroup("AgvimSession", { clear = true })
vim.api.nvim_create_autocmd(
  { "BufEnter", "BufDelete", "WinNew", "WinClosed", "TabNew", "TabClosed", "CursorHold", "DirChanged" },
  { group = group, callback = soon }
)
vim.api.nvim_create_autocmd("VimLeavePre", { group = group, callback = write })
