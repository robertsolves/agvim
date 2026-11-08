require "nvchad.autocmds"

local autocmd = vim.api.nvim_create_autocmd

-- nvim-treesitter's main branch only installs parsers; Neovim itself highlights,
-- so start it for every buffer that has a parser.
autocmd("FileType", {
  callback = function(args)
    -- Compound filetypes like "yaml.docker-compose" use the first part's parser.
    local ft = vim.bo[args.buf].filetype:match "^[^.]+"
    local lang = ft and vim.treesitter.language.get_lang(ft)
    if lang and pcall(vim.treesitter.start, args.buf, lang) then
      vim.wo[0][0].foldexpr = "v:lua.vim.treesitter.foldexpr()"
      vim.wo[0][0].foldmethod = "expr"
      vim.wo[0][0].foldlevel = 99
    end
  end,
})

-- Briefly flash yanked text.
autocmd("TextYankPost", {
  callback = function()
    vim.hl.on_yank { timeout = 150 }
  end,
})

-- Agents in the other tabs edit files on disk; reload them in the code windows.
-- Unchanged buffers reload silently; a buffer with unsaved edits asks.
vim.o.autoread = true
autocmd({ "FocusGained", "BufEnter", "CursorHold", "TermLeave", "TermClose" }, {
  callback = function()
    if vim.fn.getcmdwintype() == "" then
      vim.cmd "checktime"
    end
  end,
})
-- Also every second, since focus often stays in the agent's terminal.
vim.uv.new_timer():start(
  1000,
  1000,
  vim.schedule_wrap(function()
    if vim.api.nvim_get_mode().mode ~= "c" and vim.fn.getcmdwintype() == "" then
      vim.cmd "silent! checktime"
    end
  end)
)

-- Clicking or moving into a terminal (agent or shell) starts typing straight away.
autocmd({ "BufEnter", "WinEnter" }, {
  pattern = "term://*",
  callback = function()
    vim.cmd "startinsert"
  end,
})

-- Open files, splits and cursors come back when the project reopens.
require "configs.session"
-- :AgvimRefresh, which agvim refresh sends to each running Neovim.
require "configs.refresh"
-- The tabs' colours follow the theme.
require "configs.tab_colours"

-- Logs (lsp.log, mason.log...) grow for as long as you use Neovim: one over 5 MB is
-- emptied a few seconds after starting, so they never fill the disk.
vim.defer_fn(function()
  for _, file in ipairs(vim.fn.glob(vim.fn.stdpath "log" .. "/*.log", false, true)) do
    local stat = vim.uv.fs_stat(file)
    if stat and stat.size > 5 * 1024 * 1024 then
      local f = io.open(file, "w")
      if f then
        f:close()
      end
    end
  end
end, 5000)
