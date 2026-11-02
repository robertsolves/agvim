-- Formats on save only for filetypes listed in format_on_save_filetypes, so
-- saving a markdown, YAML or shell file never rewrites it unasked. <leader>fm
-- formats any buffer. :FormatToggle turns format-on-save off and on.
local format_on_save_filetypes = {
  dart = true, -- via the Dart LSP, so it uses the project's fvm SDK and analysis_options
  rust = true,
  lua = true,
  slint = true,
  terraform = true,
  ["terraform-vars"] = true,
}

vim.api.nvim_create_user_command("FormatToggle", function()
  vim.g.disable_autoformat = not vim.g.disable_autoformat
  vim.notify("Format on save " .. (vim.g.disable_autoformat and "off" or "on"))
end, { desc = "Toggle format on save" })

local options = {
  formatters_by_ft = {
    lua = { "stylua" },
    rust = { "rustfmt" },
    python = { "ruff_organize_imports", "ruff_format" },
    javascript = { "prettierd" },
    javascriptreact = { "prettierd" },
    typescript = { "prettierd" },
    typescriptreact = { "prettierd" },
    css = { "prettierd" },
    html = { "prettierd" },
    json = { "prettierd" },
    jsonc = { "prettierd" },
    yaml = { "prettierd" },
    markdown = { "prettierd" },
    terraform = { "terraform_fmt" },
    ["terraform-vars"] = { "terraform_fmt" },
    toml = { "taplo" },
    sh = { "shfmt" },
    bash = { "shfmt" },
  },

  default_format_opts = { lsp_format = "fallback" },

  format_on_save = function(bufnr)
    -- auto-save.nvim writes in the background; only format on deliberate saves.
    if vim.g.disable_autoformat or vim.b[bufnr].autosaving then
      return
    end
    if format_on_save_filetypes[vim.bo[bufnr].filetype] then
      return { timeout_ms = 3000 }
    end
  end,
}

return options
