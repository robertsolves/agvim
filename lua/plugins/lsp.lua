-- Everything Mason installs. Rust's rust-analyzer comes from rustup, Swift's
-- sourcekit-lsp and lldb-dap from Xcode, Dart's server from the Flutter SDK.
local mason_packages = {
  -- Lua (this config)
  "lua-language-server",
  "stylua",
  -- Python
  "basedpyright",
  "ruff",
  "debugpy",
  -- TypeScript / JavaScript
  "vtsls",
  "eslint-lsp",
  "prettierd",
  "js-debug-adapter",
  -- Rust, Bevy, Slint
  "codelldb",
  "wgsl-analyzer",
  "slint-lsp",
  -- Google Cloud / AWS
  "terraform-ls",
  "tflint",
  "dockerfile-language-server",
  "docker-compose-language-service",
  -- Config, docs, shell
  "json-lsp",
  "yaml-language-server",
  "taplo",
  "html-lsp",
  "css-lsp",
  "bash-language-server",
  "shfmt",
  "marksman",
}

return {
  {
    "neovim/nvim-lspconfig",
    dependencies = { "b0o/SchemaStore.nvim" },
    config = function()
      require "configs.lspconfig"
    end,
  },

  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = { "mason-org/mason.nvim" },
    event = "VeryLazy",
    cmd = { "MasonToolsInstall", "MasonToolsInstallSync", "MasonToolsUpdate" },
    opts = { ensure_installed = mason_packages, run_on_start = true },
  },

  {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    cmd = "ConformInfo",
    opts = function()
      return require "configs.conform"
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter").install {
        -- Neovim / shell / docs
        "lua",
        "luadoc",
        "vim",
        "vimdoc",
        "query",
        "regex",
        "printf",
        "bash",
        "markdown",
        "markdown_inline",
        "diff",
        "gitcommit",
        "git_rebase",
        "gitignore",
        "git_config",
        -- Flutter / Dart / Swift
        "dart",
        "swift",
        "kotlin",
        "groovy",
        "java",
        "objc",
        "xml",
        -- Rust / Bevy / Slint
        "rust",
        "toml",
        "ron",
        "wgsl",
        "slint",
        -- Python, web
        "python",
        "javascript",
        "typescript",
        "tsx",
        "jsdoc",
        "html",
        "css",
        "scss",
        "json",
        "json5",
        "yaml",
        "graphql",
        -- Cloud and data
        "terraform",
        "hcl",
        "dockerfile",
        "sql",
        "proto",
        "make",
        "just",
        "csv",
      }
    end,
  },
}
