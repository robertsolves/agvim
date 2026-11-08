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
    if node and node.nodes then
      api.tree.change_root_to_node(node)
    end
  end, opts "Down")
end

return {
  {
    -- Kept in this repo (local-plugins/) with fixes the GitHub version lacks.
    "dev-cetera/nvim-color-line-numbers-by-mode",
    dir = vim.fn.stdpath "config" .. "/local-plugins/nvim-color-line-numbers-by-mode",
    lazy = false,
    opts = {},
  },

  {
    "nvim-tree/nvim-tree.lua",
    -- Open the tree on start, then put the cursor back in the file you opened.
    init = function()
      vim.api.nvim_create_autocmd("VimEnter", {
        callback = function(data)
          if vim.g.diff_only then
            return
          end
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
      -- Big repos need more than the default 400ms for git status.
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

  { "tpope/vim-fugitive", cmd = { "Git", "G", "Gdiffsplit" } },

  -- VS Code's Source Control view: every changed file in a list, side-by-side
  -- diffs, stage/unstage with `-`, and file history. Good for reviewing what an
  -- agent changed.
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory" },
    keys = {
      -- Alt-g opens / closes it from anywhere, agent terminals included.
      {
        "<A-g>",
        function()
          if require("diffview.lib").get_current_view() then
            vim.cmd "DiffviewClose"
          else
            vim.cmd "stopinsert"
            -- In a worktree (lib/worktree), everything since it branched off,
            -- committed or not; elsewhere what isn't committed yet.
            local base = vim.env.AGVIM_BASE
            if base and base ~= "" then
              local fork = vim.trim(vim.fn.system { "git", "merge-base", base, "HEAD" })
              vim.cmd("DiffviewOpen " .. (vim.v.shell_error == 0 and fork or vim.fn.fnameescape(base)))
            else
              vim.cmd "DiffviewOpen"
            end
          end
        end,
        mode = { "n", "t" },
        desc = "Git: show / hide all changes",
      },
      { "<leader>gv", "<cmd>DiffviewOpen<cr>", desc = "Git: view all changes" },
      { "<leader>gV", "<cmd>DiffviewClose<cr>", desc = "Git: close changes view" },
      { "<leader>gf", "<cmd>DiffviewFileHistory %<cr>", desc = "Git: this file's history" },
      { "<leader>gF", "<cmd>DiffviewFileHistory<cr>", desc = "Git: project history" },
    },
    opts = {
      hooks = {
        -- `gd` starts Neovim just for the changes view; closing it quits.
        view_closed = function()
          if vim.g.diff_only then
            vim.cmd "qall"
          end
        end,
      },
    },
  },
}
