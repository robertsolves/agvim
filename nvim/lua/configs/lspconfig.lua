-- Load NvChad defaults (lua_ls, capabilities, LspAttach keymaps).
require("nvchad.configs.lspconfig").defaults()

-- Diagnostics: no inline text by default (toggle with <leader>qv), signs and
-- underlines on, full message in a float with <leader>qt.
vim.diagnostic.config {
  virtual_text = false,
  signs = true,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
  float = { border = "rounded", source = true },
}

-- Dart (flutter-tools) and Rust (rustaceanvim) start their own servers.
local servers = {
  -- Python: types from basedpyright, lint + format from ruff.
  basedpyright = {
    settings = {
      basedpyright = {
        analysis = { typeCheckingMode = "standard" },
        disableOrganizeImports = true,
      },
    },
    -- Use the project's .venv (uv, poetry, venv) when there is one.
    before_init = function(_, config)
      local python = config.root_dir and config.root_dir .. "/.venv/bin/python"
      if python and vim.uv.fs_stat(python) then
        config.settings.python = { pythonPath = python }
      end
    end,
  },
  ruff = {
    on_attach = function(client)
      client.server_capabilities.hoverProvider = false
    end,
  },

  -- TypeScript / JavaScript.
  vtsls = {},
  eslint = {},

  -- Swift and Objective-C. Ships with Xcode. SwiftPM projects work as they are;
  -- for a Flutter ios/ folder run :XcodeBuildServer once so it knows the Xcode
  -- project (otherwise "No such module 'Flutter'").
  sourcekit = {
    cmd = { "xcrun", "sourcekit-lsp" },
    filetypes = { "swift", "objc", "objcpp" },
  },

  -- C/C++ in plugins and the Windows/Linux runners. Xcode's clangd.
  clangd = { filetypes = { "c", "cpp" } },

  -- Flutter's android/ folder: Kotlin and Gradle .kts (JetBrains' server),
  -- AndroidManifest and other XML, plus SVG validation.
  kotlin_lsp = {},
  lemminx = {
    -- Android XML has no schema; don't warn about that on every file.
    settings = { xml = { validation = { noGrammar = "ignore" } } },
  },
  neocmake = {},

  -- Slint UI + Bevy shaders.
  slint_lsp = {},
  wgsl_analyzer = {},

  -- Google Cloud / AWS infrastructure.
  terraformls = {},
  tflint = {},
  dockerls = {},
  docker_compose_language_service = {},

  -- Config and docs.
  jsonls = {
    before_init = function(_, config)
      config.settings.json.schemas = require("schemastore").json.schemas()
      -- VS Code's own JSONC files allow trailing commas.
      table.insert(config.settings.json.schemas, {
        fileMatch = { ".vscode/*.json", "*.code-workspace" },
        schema = { allowTrailingCommas = true },
      })
    end,
    settings = { json = { validate = { enable = true } } },
  },
  yamlls = {
    before_init = function(_, config)
      config.settings.yaml.schemas = require("schemastore").yaml.schemas()
    end,
    settings = {
      yaml = {
        schemaStore = { enable = false, url = "" },
        keyOrdering = false,
        -- CloudFormation intrinsic functions.
        customTags = {
          "!Ref",
          "!Sub",
          "!Sub sequence",
          "!GetAtt",
          "!GetAtt sequence",
          "!Join sequence",
          "!If sequence",
          "!Equals sequence",
          "!Not sequence",
          "!And sequence",
          "!Or sequence",
          "!FindInMap sequence",
          "!Select sequence",
          "!Split sequence",
          "!ImportValue",
          "!Base64",
          "!Cidr sequence",
          "!GetAZs",
          "!Condition",
        },
      },
    },
  },
  taplo = {},
  html = {},
  cssls = {},
  bashls = {},
  marksman = {},
}

for name, config in pairs(servers) do
  vim.lsp.config(name, config)
  vim.lsp.enable(name)
end

-- Points sourcekit-lsp at the Xcode workspace of the ios/ or macos/ folder you're
-- in (needs `brew install xcode-build-server` and one Xcode or `flutter build ios`
-- build). Writes buildServer.json there; add it to the project's git ignores.
vim.api.nvim_create_user_command("XcodeBuildServer", function()
  local workspace = vim.fs.find(function(name)
    return name:match "%.xcworkspace$" and name ~= "project.xcworkspace"
  end, { upward = true, path = vim.fn.expand "%:p:h", type = "directory" })[1]
  if not workspace then
    vim.notify("No .xcworkspace above this file", vim.log.levels.ERROR)
    return
  end
  local dir = vim.fs.dirname(workspace)
  local result = vim
    .system({
      "xcode-build-server",
      "config",
      "-workspace",
      vim.fs.basename(workspace),
      "-scheme",
      "Runner",
    }, { cwd = dir, text = true })
    :wait()
  if result.code ~= 0 then
    vim.notify(result.stderr, vim.log.levels.ERROR)
    return
  end
  vim.notify("Wrote " .. dir .. "/buildServer.json; restarting sourcekit")
  vim.cmd "lsp restart sourcekit"
end, { desc = "Configure sourcekit-lsp for this Xcode workspace (scheme Runner)" })
