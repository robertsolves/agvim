return {
  {
    -- Starts rust-analyzer (from rustup) and finds codelldb from Mason for debugging.
    "mrcjkb/rustaceanvim",
    version = "^9",
    lazy = false,
    init = function()
      vim.g.rustaceanvim = {
        tools = { test_executor = "background" },
        server = {
          default_settings = {
            ["rust-analyzer"] = {
              cargo = {
                buildScripts = { enable = true },
                -- Separate target dir, so rust-analyzer's checks don't hold the
                -- cargo lock while you `cargo run` a Bevy game. Costs disk space.
                targetDir = true,
              },
              check = { command = "clippy" },
              procMacro = { enable = true },
              -- Bevy's macro-heavy code base is slow to index otherwise.
              files = { excludeDirs = { ".git", "target", "node_modules" } },
            },
          },
        },
      }
    end,
  },

  {
    -- Versions, features and docs for crates in Cargo.toml, through an in-process LSP.
    "saecki/crates.nvim",
    event = "BufRead Cargo.toml",
    opts = {
      lsp = { enabled = true, actions = true, completion = true, hover = true },
    },
  },
}
