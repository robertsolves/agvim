require "nvchad.autocmds"

local autocmd = vim.api.nvim_create_autocmd

-- nvim-treesitter's main branch only installs parsers; Neovim itself highlights,
-- so start it for every buffer that has a parser.
autocmd("FileType", {
  callback = function(args)
    -- Compound filetypes like "yaml.docker-compose" use the first part's parser.
    local lang = vim.treesitter.language.get_lang(vim.bo[args.buf].filetype:match "^[^.]+")
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

-- Agents in the bottom panel edit files on disk; reload them in the code windows
-- above. Unchanged buffers reload silently; a buffer with unsaved edits asks.
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
