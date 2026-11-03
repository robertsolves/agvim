return {
  {
    "nvim-flutter/flutter-tools.nvim",
    ft = "dart",
    dependencies = { "nvim-lua/plenary.nvim", "mfussenegger/nvim-dap" },
    opts = function()
      return {
        -- Use the project's .fvm/flutter_sdk when there is one.
        fvm = true,
        ui = { border = "rounded" },
        widget_guides = { enabled = true },
        closing_tags = { enabled = true, prefix = "// " },
        dev_log = { enabled = true, open_cmd = "botright 15split" },
        -- :FlutterRun runs under nvim-dap, so breakpoints work. Configs from
        -- .vscode/launch.json (type "dart") are loaded too.
        debugger = { enabled = true },
        lsp = {
          capabilities = require("nvchad.configs.lspconfig").capabilities,
          settings = {
            showTodos = true,
            completeFunctionCalls = true,
            renameFilesWithClasses = "prompt",
            updateImportsOnRename = true,
            enableSnippets = true,
          },
        },
      }
    end,
  },
}
