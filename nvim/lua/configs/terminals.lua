-- A VS Code-style terminal panel along the bottom: any number of terminals
-- (shells and coding agents), shown one at a time as tabs, or side by side.
-- Terminals keep running while the panel is hidden. The tab bar on top of the
-- panel lists them; the current one is highlighted.
local M = {}

-- Agent CLIs on <leader>t + key. Each press starts another one. Claude starts
-- connected to claudecode.nvim, so it sees your selection and shows its edits as
-- diffs (accept with <leader>aa).
M.agents = {
  { key = "c", name = "claude", cmd = "claude" },
  { key = "x", name = "codex", cmd = "codex" },
  { key = "o", name = "opencode", cmd = "opencode" },
  { key = "k", name = "kilo", cmd = "kilo" },
  { key = "g", name = "gemini", cmd = "gemini" },
}

local PANEL_HEIGHT = 0.35

---@type { buf: integer, name: string }[]
local terminals = {}
local current = 0 -- index into terminals

local function is_terminal(buf)
  for i, term in ipairs(terminals) do
    if term.buf == buf then
      return i
    end
  end
end

-- Windows currently showing one of the panel's terminals.
local function panel_windows()
  local wins = {}
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if is_terminal(vim.api.nvim_win_get_buf(win)) then
      table.insert(wins, win)
    end
  end
  return wins
end

function M.winbar()
  local shown = vim.api.nvim_win_get_buf(vim.g.statusline_winid or 0)
  local parts = {}
  for i, term in ipairs(terminals) do
    local hl = term.buf == shown and "%#TabLineSel#" or "%#TabLine#"
    table.insert(parts, hl .. " " .. i .. " " .. term.name .. " ")
  end
  return table.concat(parts, "%#TabLineFill# ") .. "%#TabLineFill#"
end

local function style_window(win)
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].signcolumn = "no"
  vim.wo[win].winfixheight = true
  vim.wo[win].winbar = "%!v:lua.require'configs.terminals'.winbar()"
end

-- The panel's window: the focused one if it's in the panel, else any panel
-- window, else a new full-width split along the bottom.
local function panel_window()
  local wins = panel_windows()
  local focused = vim.api.nvim_get_current_win()
  if vim.tbl_contains(wins, focused) then
    return focused
  end
  if wins[1] then
    return wins[1]
  end
  vim.cmd("botright " .. math.floor(vim.o.lines * PANEL_HEIGHT) .. "split")
  local win = vim.api.nvim_get_current_win()
  style_window(win)
  return win
end

local function show(index, win)
  current = index
  win = win or panel_window()
  vim.api.nvim_win_set_buf(win, terminals[index].buf)
  style_window(win)
  vim.api.nvim_set_current_win(win)
  vim.cmd "startinsert"
  vim.cmd "redrawstatus!"
end

local function unique_name(name)
  local taken = {}
  for _, term in ipairs(terminals) do
    taken[term.name] = true
  end
  local candidate, n = name, 1
  while taken[candidate] do
    n = n + 1
    candidate = name .. " " .. n
  end
  return candidate
end

local function ide_env(name)
  local ok, claudecode = pcall(require, "claudecode")
  if name ~= "claude" or not ok or not claudecode.state.port then
    return nil
  end
  return {
    ENABLE_IDE_INTEGRATION = "true",
    FORCE_CODE_TERMINAL = "true",
    CLAUDE_CODE_SSE_PORT = tostring(claudecode.state.port),
  }
end

-- Starts a new terminal in the panel. `cmd` nil means a shell; `win` reuses a
-- given window (used by split).
function M.new(name, cmd, win)
  name = name or "shell"
  win = win or panel_window()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(win, buf)
  vim.api.nvim_win_call(win, function()
    vim.fn.jobstart(cmd and { vim.o.shell, "-c", cmd } or { vim.o.shell }, {
      term = true,
      cwd = vim.fn.getcwd(),
      env = ide_env(name),
    })
  end)
  vim.bo[buf].buflisted = false -- keep terminals out of the buffer tabs above
  table.insert(terminals, { buf = buf, name = unique_name(name) })
  show(#terminals, win)
end

-- Another terminal beside the current one, inside the panel.
function M.split(name, cmd)
  local win = panel_window()
  vim.api.nvim_set_current_win(win)
  vim.cmd "rightbelow vsplit"
  M.new(name, cmd, vim.api.nvim_get_current_win())
end

-- Hides the panel, or shows it again (with a shell if there's nothing yet).
function M.toggle()
  local wins = panel_windows()
  if #wins > 0 then
    for _, win in ipairs(wins) do
      pcall(vim.api.nvim_win_close, win, true)
    end
    return
  end
  if #terminals == 0 then
    return M.new()
  end
  show(math.max(current, 1))
end

-- Next / previous terminal in the focused panel window.
function M.cycle(step)
  if #terminals == 0 then
    return M.new()
  end
  local here = is_terminal(vim.api.nvim_get_current_buf()) or current
  show((here - 1 + step) % #terminals + 1)
end

function M.pick()
  vim.ui.select(terminals, {
    prompt = "Terminal",
    format_item = function(term)
      return term.name
    end,
  }, function(_, index)
    if index then
      show(index)
    end
  end)
end

function M.rename()
  local index = is_terminal(vim.api.nvim_get_current_buf())
  if not index then
    return
  end
  vim.ui.input({ prompt = "Name: ", default = terminals[index].name }, function(name)
    if name and name ~= "" then
      terminals[index].name = name
      vim.cmd "redrawstatus!"
    end
  end)
end

-- Closing a terminal's program removes its tab and shows a neighbour.
vim.api.nvim_create_autocmd("TermClose", {
  callback = function(args)
    local index = is_terminal(args.buf)
    if not index then
      return
    end
    table.remove(terminals, index)
    vim.schedule(function()
      local wins = vim.fn.win_findbuf(args.buf)
      if #terminals == 0 then
        for _, win in ipairs(wins) do
          pcall(vim.api.nvim_win_close, win, true)
        end
      else
        current = math.min(index, #terminals)
        for _, win in ipairs(wins) do
          vim.api.nvim_win_set_buf(win, terminals[current].buf)
        end
      end
      pcall(vim.api.nvim_buf_delete, args.buf, { force = true })
      vim.cmd "redrawstatus!"
    end)
  end,
})

-- Opening a project folder (`nvim .`, which `t`, `p` and Finder's Open in Neovim
-- do) starts with a shell in the panel; the cursor stays in the code.
-- Read now: by VimEnter, nvim-tree has replaced the folder argument.
local opened_folder = vim.fn.argc() == 1 and vim.fn.isdirectory(vim.fn.argv(0)) == 1
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    if opened_folder then
      vim.schedule(function()
        local code_win = vim.api.nvim_get_current_win()
        M.new()
        vim.cmd "stopinsert"
        vim.api.nvim_set_current_win(code_win)
      end)
    end
  end,
})

return M
