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
