# Neovim config (NvChad, macOS)

NvChad v2.5 on Neovim 0.12, set up for Flutter/Dart, Rust (Bevy, Slint), Swift, Python, TypeScript/JavaScript, Terraform (Google Cloud), Docker, YAML/JSON (GitHub Actions, CloudFormation) and Claude Code.

## Setup

1. `brew install neovim tmux ripgrep fd lazygit tree-sitter-cli`
2. Install the SDKs you use: Flutter (fvm projects are picked up from `.fvm/flutter_sdk`), Rust via rustup (`rustup component add rust-analyzer clippy`), Xcode (Swift's `sourcekit-lsp` and `lldb-dap`), Node, Python, Terraform.
3. Clone this repo to `~/.config/nvim` and run `nvim`. Plugins, treesitter parsers and Mason tools install on first start.
4. Use a Nerd Font in the terminal (kitty: `font_family JetBrainsMono Nerd Font`).

Mason builds basedpyright and debugpy with the first `python3` on PATH. Homebrew's Python 3.15 can't create venvs with pip on macOS 26 (`platform.mac_ver()` is empty), so if those fail, install them with 3.14 first on PATH:

```sh
mkdir -p /tmp/py314 && ln -sf /opt/homebrew/bin/python3.14 /tmp/py314/python3
PATH=/tmp/py314:$PATH nvim --headless "+MasonToolsInstallSync" +qa
```

## Where things live

| Area | Files |
|---|---|
| Plugins | `lua/plugins/*.lua`, one file per area |
| Language servers | `lua/configs/lspconfig.lua` (Dart: `plugins/flutter.lua`, Rust: `plugins/rust.lua`) |
| Formatting | `lua/configs/conform.lua` |
| Debuggers | `lua/configs/dap.lua` |
| Keys | `lua/mappings.lua`, plus `after/ftplugin/{dart,rust,slint}.lua` |

## Keys

Leader is Space. `Space` then wait shows every key (which-key). `Space ch` opens NvChad's cheat sheet.

| Keys | Does |
|---|---|
| `Space ff` / `Space fw` / `Space fb` | find file / grep / buffers |
| `Ctrl-n` / `Space e` | toggle / focus file tree |
| `Tab` / `Shift-Tab` / `Space x` | next / previous / close buffer |
| `Ctrl-h/j/k/l` | move between splits and tmux panes |
| `gd`, `Space gr`, `Space gi` | definition, references, implementations |
| `K`, `Space ca`, `Space rs` | hover, code action, rename |
| `Space fm` | format (also on save for Dart, Rust, Lua, Slint, Terraform; `:FormatToggle`) |
| `Space xx` / `Space xt` / `Space xv` | all problems / line problem / inline problem text |
| `]e` / `[e`, `]d` / `[d` | next / previous error, diagnostic |
| `Space ih` | inlay hints |
| `Space rr` | project search and replace (regex) |
| `F5` `F9` `F10` `F11` `Shift-F11` `Shift-F5` | debug: start/continue, breakpoint, over, into, out, stop |
| `Space du` / `Space dh` | debugger UI / evaluate |
| `Space Fr` `Fh` `FR` `Fq` `Fd` `Fo` `Fl` | Flutter: run, hot reload, restart, quit, devices, outline, log |
| `Space Rr` `Rd` `Re` `Rm` `dt` | Rust: run, debug, explain error, expand macro, tests |
| `Space sp` | Slint live preview |
| `Space ac` `as` `ab` `aa` `ad` | Claude Code: open, send selection, add file, accept/reject diff |
| `Space gg` / `Space gh` / `Space gb` | lazygit / preview hunk / blame line |
| `Alt-i` / `Alt-h` / `Alt-v` | floating / horizontal / vertical terminal |
| `jk` | leave insert mode |

## Debugging

`F5` lists the configs for the current file type, including the project's `.vscode/launch.json`.

- Flutter/Dart: `Space Fr` (`:FlutterRun`) runs the app under the debugger.
- Rust: `Space Rd` (`:RustLsp debuggables`), codelldb from Mason.
- Swift (SwiftPM): `F5` builds with `swift build` and debugs with Xcode's lldb-dap. VS Code `"type": "swift"` configs work too.
- Python: `F5`, debugpy; the program runs in the project's `.venv`.
- JS/TS: `F5`, js-debug (Node runs `.ts` directly).
