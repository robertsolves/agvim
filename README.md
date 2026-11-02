# Neovim config (NvChad, macOS)

NvChad v2.5 on Neovim 0.12, set up for Flutter/Dart (plus the iOS and Android folders: Swift, Objective-C, Kotlin, Gradle, XML, Podfile), Rust (Bevy, Slint), Swift, Python, TypeScript/JavaScript, Terraform (Google Cloud), Docker, YAML/JSON/TOML (GitHub Actions, CloudFormation), with image and SVG/HTML previews and coding agents in a bottom panel.

## How it's meant to be used

Code on top, agents below. `Space tc` opens Claude in a panel along the bottom (already connected, so it sees your selection and shows edits as diffs: `Space aa` / `Space ad`). `Space tx` Codex, `Space to` OpenCode, `Space tk` Kilo, `Space tg` Gemini, `Space tt` (or Ctrl-`) a plain shell. Each toggles and keeps running while hidden. Files an agent changes reload above within a second. In a terminal, `Ctrl-w` (or `Ctrl-x`) returns to normal mode, then `Ctrl-k` moves up to the code.

## Setup

1. `brew install neovim tmux ripgrep fd lazygit tree-sitter-cli`
2. Install the SDKs you use: Flutter (fvm projects are picked up from `.fvm/flutter_sdk`), Rust via rustup (`rustup component add rust-analyzer clippy`), Xcode (Swift's `sourcekit-lsp` and `lldb-dap`), Node, Python, Terraform.
3. `brew install imagemagick xcode-build-server` (JPG/SVG images, Flutter iOS code intelligence).
4. Clone this repo to `~/.config/nvim` and run `nvim`. Plugins, treesitter parsers and Mason tools install on first start.
5. Use a Nerd Font in the terminal (kitty: `font_family JetBrainsMono Nerd Font`).

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
| `Space tt` or Ctrl-` | bottom terminal |
| `Space tc` `tx` `to` `tk` `tg` | Claude, Codex, OpenCode, Kilo, Gemini in the bottom panel |
| `Space pi` | SVG rendered in a float (first frame), or the image under the cursor |
| `Space pv` / `Space pc` | live browser preview of SVG (animated SMIL plays), HTML, Markdown / stop |
| `Alt-i` / `Alt-h` / `Alt-v` | floating / horizontal / vertical terminal |
| `jk` | leave insert mode |

## Debugging

`F5` lists the configs for the current file type, including the project's `.vscode/launch.json`.

- Flutter/Dart: `Space Fr` (`:FlutterRun`) runs the app under the debugger.
- Rust: `Space Rd` (`:RustLsp debuggables`), codelldb from Mason.
- Swift (SwiftPM): `F5` builds with `swift build` and debugs with Xcode's lldb-dap. VS Code `"type": "swift"` configs work too.
- Python: `F5`, debugpy; the program runs in the project's `.venv`.
- JS/TS: `F5`, js-debug (Node runs `.ts` directly).

## Images and previews

Opening a `.png`, `.jpg`, `.gif` or `.webp` shows the picture (kitty graphics; works inside tmux with `allow-passthrough on`). `.svg` opens as editable XML: `Space pi` shows it rendered, `Space pv` opens it in the browser where SMIL animations play, updating as you type. HTML previews in the browser too and refreshes on save.

## Flutter iOS folder

Swift and Objective-C in `ios/` need to know the Xcode project. Once per app: build it once (`fvm flutter build ios --debug --no-codesign` or in Xcode), open a file in `ios/`, run `:XcodeBuildServer`. It writes `ios/buildServer.json`; keep that out of git.
