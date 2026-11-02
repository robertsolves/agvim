-- Use the local clone of the line-number plugin while its fixes aren't pushed.
local line_numbers_dir = vim.fn.expand "~/Projects/nvim/nvim-color-line-numbers-by-mode"

-- NvimTree with custom keymaps
local function nvim_tree_on_attach(bufnr)
  local api = require "nvim-tree.api"
  local function opts(desc)
    return { desc = "nvim-tree: " .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
  end

  -- Default mappings from nvim-tree
  api.config.mappings.default_on_attach(bufnr)
  -- Custom mappings
  vim.keymap.set("n", "?", api.tree.toggle_help, opts "Help")
  vim.keymap.set("n", "\\", api.tree.change_root_to_parent, opts "Up")
  vim.keymap.set("n", "<C-CR>", function()
    local node = api.tree.get_node_under_cursor()
    if node.nodes then
      api.tree.change_root_to_node(node)
    end
  end, opts "Down")
end

return {
  {
    "dev-cetera/nvim-color-line-numbers-by-mode",
    dir = vim.uv.fs_stat(line_numbers_dir) and line_numbers_dir or nil,
    lazy = false,
    opts = {},
  },

  {
    "nvim-tree/nvim-tree.lua",
    -- Open the tree on start, then put the cursor back in the file you opened.
    init = function()
      vim.api.nvim_create_autocmd("VimEnter", {
        callback = function(data)
          local opened_file = vim.fn.filereadable(data.file) == 1
          require("nvim-tree.api").tree.open()
          if opened_file then
            vim.cmd.wincmd "p"
          end
        end,
      })
    end,
    opts = function()
      local opts = require "nvchad.configs.nvimtree"
      opts.view = vim.tbl_extend("force", opts.view or {}, { width = 60 })
      opts.on_attach = nvim_tree_on_attach
      -- Big repos like compledo need more than the default 400ms for git status.
      opts.git = vim.tbl_extend("force", opts.git or {}, { timeout = 3000 })
      return opts
    end,
  },

  {
    "okuuva/auto-save.nvim",
    version = "^1",
    cmd = "ASToggle",
    event = { "InsertLeave", "TextChanged" },
    -- Mark auto-saves so conform skips format-on-save for them.
    init = function()
      vim.api.nvim_create_autocmd("User", {
        pattern = "AutoSaveWritePre",
        callback = function(args)
          vim.b[args.data.saved_buffer].autosaving = true
        end,
      })
      vim.api.nvim_create_autocmd("User", {
        pattern = "AutoSaveWritePost",
        callback = function(args)
          vim.b[args.data.saved_buffer].autosaving = false
        end,
      })
    end,
    opts = {},
  },

  -- Ctrl-h/j/k/l move between Neovim splits and tmux panes alike.
  {
    "christoomey/vim-tmux-navigator",
    cmd = { "TmuxNavigateLeft", "TmuxNavigateDown", "TmuxNavigateUp", "TmuxNavigateRight" },
    keys = {
      { "<C-h>", "<cmd>TmuxNavigateLeft<cr>", desc = "Window left" },
      { "<C-j>", "<cmd>TmuxNavigateDown<cr>", desc = "Window down" },
      { "<C-k>", "<cmd>TmuxNavigateUp<cr>", desc = "Window up" },
      { "<C-l>", "<cmd>TmuxNavigateRight<cr>", desc = "Window right" },
    },
  },

  {
    "folke/trouble.nvim",
    cmd = "Trouble",
    opts = {},
    keys = {
      { "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnostics (Trouble)" },
      { "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Buffer Diagnostics (Trouble)" },
      { "<leader>cs", "<cmd>Trouble symbols toggle focus=false<cr>", desc = "Symbols (Trouble)" },
      { "<leader>cl", "<cmd>Trouble lsp toggle focus=false win.position=right<cr>", desc = "LSP refs/defs (Trouble)" },
      { "<leader>xL", "<cmd>Trouble loclist toggle<cr>", desc = "Location List (Trouble)" },
      { "<leader>xQ", "<cmd>Trouble qflist toggle<cr>", desc = "Quickfix List (Trouble)" },
    },
  },

  {
    "folke/todo-comments.nvim",
    event = "User FilePost",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {},
  },

  -- Project-wide search and replace, with regex.
  {
    "MagicDuck/grug-far.nvim",
    cmd = "GrugFar",
    opts = {},
  },

  { "tpope/vim-fugitive", cmd = { "Git", "G", "Gdiffsplit", "Gblame" } },
}
