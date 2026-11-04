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
  -- Flutter's android/ (Kotlin, Gradle .kts, XML) and windows/linux runners (CMake)
  "kotlin-lsp",
  "lemminx",
  "neocmakelsp",
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
    -- Loaded after VimEnter, which its own start-up check waits for, so start it here.
    -- This is what installs the language servers the first time Neovim opens.
    config = function(_, opts)
      -- Mason builds Python tools with the first python3 on PATH. Homebrew's Python 3.15
      -- on macOS 26 makes venvs without pip (platform.mac_ver() is empty), so put an
      -- older working Python first, for this Neovim.
      vim.fn.system { "python3", "-c", "import platform, sys; sys.exit(0 if platform.mac_ver()[0] else 1)" }
      if vim.v.shell_error ~= 0 then
        for _, version in ipairs { "3.14", "3.13", "3.12" } do
          local python = vim.fn.exepath("python" .. version)
          if python ~= "" then
            local shim = vim.fn.stdpath "cache" .. "/agentnv-python"
            vim.fn.mkdir(shim, "p")
            vim.uv.fs_unlink(shim .. "/python3")
            vim.uv.fs_symlink(python, shim .. "/python3")
            vim.env.PATH = shim .. ":" .. vim.env.PATH
            break
          end
        end
      end
      local installer = require "mason-tool-installer"
      installer.setup(opts)
      installer.run_on_start()
    end,
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
      require("nvim-treesitter").install(require "configs.treesitter_parsers")
    end,
  },
}
