require "nvchad.options"

local o = vim.o

o.textwidth = 100 -- Set textwidth for wrapping
o.colorcolumn = "80,100" -- Visual guides for lines
o.number = true -- Absolute number on the cursor line
o.relativenumber = true -- Relative numbers everywhere else
o.cursorline = true
o.cursorlineopt = "number" -- Highlight only the cursor line's number
o.signcolumn = "yes" -- Stop the text jumping when diagnostics appear
o.scrolloff = 8
o.updatetime = 250
o.confirm = true -- Ask instead of failing on :q with unsaved changes
o.scrollback = 100000 -- Long terminal history for agent sessions

-- Colour swatches next to colour values (Flutter Colors, CSS), from the LSP.
vim.lsp.document_color.enable(true)

-- Filetypes Neovim doesn't know about out of the box.
vim.filetype.add {
  extension = {
    slint = "slint",
    wgsl = "wgsl",
    ron = "ron",
    dbml = "dbml",
    tf = "terraform",
    tfvars = "terraform-vars",
    env = "dotenv",
    -- iOS / macOS (Flutter ios/ and macos/ folders)
    m = "objc",
    mm = "objcpp",
    plist = "xml",
    storyboard = "xml",
    xib = "xml",
    entitlements = "xml",
    xcscheme = "xml",
    xcworkspacedata = "xml",
    xcconfig = "xcconfig",
    podspec = "ruby",
  },
  filename = {
    [".env"] = "dotenv",
    ["Podfile"] = "ruby",
  },
  pattern = {
    ["%.env%.[%w_.-]+"] = "dotenv",
    ["docker%-compose.*%.ya?ml"] = "yaml.docker-compose",
    ["compose%.ya?ml"] = "yaml.docker-compose",
    [".*/%.vscode/.*%.json"] = "jsonc", -- VS Code allows comments and trailing commas
  },
}

-- Highlight these with a related language's parser.
vim.treesitter.language.register("bash", "dotenv")
vim.treesitter.language.register("terraform", "terraform-vars")
vim.treesitter.language.register("xml", "svg")
vim.treesitter.language.register("properties", { "jproperties", "xcconfig" })
