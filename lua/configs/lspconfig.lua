-- Load NvChad defaults (lua_ls, capabilities, LspAttach keymaps).
require("nvchad.configs.lspconfig").defaults()

-- Diagnostics: no inline text by default (toggle with <leader>xv), signs and
-- underlines on, full message in a float with <leader>xt.
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

  -- Swift (SwiftPM projects). Ships with Xcode.
  sourcekit = {
    cmd = { "xcrun", "sourcekit-lsp" },
    filetypes = { "swift" },
  },

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
