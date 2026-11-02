require "nvchad.mappings"

local map = vim.keymap.set
local opts = { noremap = true, silent = true }

local function with_desc(desc)
  return vim.tbl_extend("force", opts, { desc = desc })
end

--------------------------------------------------------------------------------
-- General Mappings
--------------------------------------------------------------------------------

map("n", "<Leader>//-", function()
  require("configs.add_comment_separator").add_comment_separator()
end, with_desc "Insert comment separator")

-- Exit terminal mode using 'C-w'.
map("t", "<C-w>", "<C-\\><C-N>", opts)

-- Exit insert mode using 'jk'.
map("i", "jk", "<Esc>", opts)

-- F13: Enter Normal mode (from any mode).
map({ "i", "n", "v", "c", "t" }, "<F13>", "<Esc>", opts)

-- F14: Enter Insert mode (from any mode).
map({ "i", "n", "v", "c", "t" }, "<F14>", "<Esc>i", opts)

-- F15: Enter Visual mode (from any mode).
map({ "i", "n", "v", "c", "t" }, "<F15>", "<Esc>v", opts)

-- F16: Enter Command mode (from any mode).
map({ "i", "n", "v", "c", "t" }, "<F16>", '<Esc><Cmd>call feedkeys(":")<CR>', opts)

-- F19: Exit Terminal mode.
map("t", "<F19>", "exit<CR>", opts)

-- F19: Write out current buffer (while in insert mode).
map("i", "<F19>", "<Esc>:w<CR>a", opts)

--------------------------------------------------------------------------------
-- Diagnostics
--------------------------------------------------------------------------------

-- Show the full message for the current line.
map("n", "<Leader>xt", function()
  vim.diagnostic.open_float { scope = "line" }
end, with_desc "Line diagnostics")

-- Toggle inline error text.
map("n", "<Leader>xv", function()
  local on = not vim.diagnostic.config().virtual_text
  vim.diagnostic.config { virtual_text = on }
end, with_desc "Toggle inline diagnostics")

map("n", "]e", function()
  vim.diagnostic.jump { count = 1, severity = vim.diagnostic.severity.ERROR, float = true }
end, with_desc "Next error")
map("n", "[e", function()
  vim.diagnostic.jump { count = -1, severity = vim.diagnostic.severity.ERROR, float = true }
end, with_desc "Previous error")

--------------------------------------------------------------------------------
-- LSP Mappings (Neovim also maps K hover, grn rename, gra actions, grr refs)
--------------------------------------------------------------------------------

-- Refactor a symbol.
map({ "n", "v" }, "<Leader>rs", vim.lsp.buf.rename, with_desc "Refactor a symbol")

-- Search and replace across the project with regex.
map({ "n", "v" }, "<Leader>rr", "<cmd>GrugFar<CR>", with_desc "Replace text using regex")

-- Code actions (quick fixes, imports, wrap widget, etc.).
map({ "n", "v" }, "<Leader>ca", vim.lsp.buf.code_action, with_desc "Code action")

-- Show hover information.
map("n", "<Leader>I", vim.lsp.buf.hover, with_desc "Show hover information")

-- Go to the definition of a symbol.
map("n", "<Leader>gd", vim.lsp.buf.definition, with_desc "Go to the definition")

-- Find references to a symbol.
map("n", "<Leader>gr", "<cmd>Telescope lsp_references<CR>", with_desc "Find references")

-- Go to implementations.
map("n", "<Leader>gi", "<cmd>Telescope lsp_implementations<CR>", with_desc "Find implementations")

-- Search symbols in the workspace.
map("n", "<Leader>fs", "<cmd>Telescope lsp_dynamic_workspace_symbols<CR>", with_desc "Find workspace symbols")

-- Toggle inlay hints (types, parameter names).
map("n", "<Leader>ih", function()
  vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
end, with_desc "Toggle inlay hints")

--------------------------------------------------------------------------------
-- NVIM DAP Mappings (F5/F9/F10/F11 are in plugins/debug.lua)
--------------------------------------------------------------------------------

local function dap(fn)
  return function()
    require("dap")[fn]()
  end
end

map("n", "<Leader>dl", dap "step_into", with_desc "Step into")
map("n", "<Leader>dj", dap "step_over", with_desc "Step over")
map("n", "<Leader>dk", dap "step_out", with_desc "Step out")
map("n", "<Leader>dc", dap "continue", with_desc "Continue")
map("n", "<Leader>db", dap "toggle_breakpoint", with_desc "Toggle breakpoint")
map("n", "<Leader>dd", function()
  require("dap").set_breakpoint(vim.fn.input "Breakpoint condition: ")
end, with_desc "Set conditional breakpoint")
map("n", "<Leader>de", dap "terminate", with_desc "Terminate debugger")
map("n", "<Leader>dr", dap "run_last", with_desc "Run last session")
map("n", "<Leader>du", function()
  require("dapui").toggle()
end, with_desc "Toggle debugger UI")
map({ "n", "v" }, "<Leader>dh", function()
  require("dapui").eval()
end, with_desc "Evaluate expression")

--------------------------------------------------------------------------------
-- Git Mappings
--------------------------------------------------------------------------------

map("n", "<Leader>gh", "<cmd>Gitsigns preview_hunk<CR>", with_desc "Preview hunk")
map("n", "<Leader>gb", "<cmd>Gitsigns blame_line<CR>", with_desc "Blame line")
map("n", "]h", "<cmd>Gitsigns next_hunk<CR>", with_desc "Next hunk")
map("n", "[h", "<cmd>Gitsigns prev_hunk<CR>", with_desc "Previous hunk")

-- lazygit in a floating terminal.
map("n", "<Leader>gg", function()
  require("nvchad.term").toggle { pos = "float", id = "lazygit", cmd = "lazygit" }
end, with_desc "lazygit")

--------------------------------------------------------------------------------
-- Bottom terminal panel and coding agents (configs/terminals.lua)
--------------------------------------------------------------------------------

local terminals = require "configs.terminals"

-- Ctrl-` like VS Code; <leader>tt does the same.
map({ "n", "t" }, "<C-`>", function()
  terminals.toggle "shell"
end, with_desc "Toggle bottom terminal")
map("n", "<Leader>tt", function()
  terminals.toggle "shell"
end, with_desc "Toggle bottom terminal")

for _, agent in ipairs(terminals.agents) do
  map({ "n", "t" }, "<Leader>t" .. agent.key, function()
    terminals.toggle(agent.name, agent.cmd)
  end, with_desc("Toggle " .. agent.name))
end
