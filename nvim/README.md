# Neovim config (NvChad, macOS)

NvChad v2.5 on Neovim 0.12, set up for Flutter/Dart (plus the iOS and Android folders: Swift, Objective-C, Kotlin, Gradle, XML, Podfile), Rust (Bevy, Slint), Swift, Python, TypeScript/JavaScript, Terraform (Google Cloud), Docker, YAML/JSON/TOML (GitHub Actions, CloudFormation), with image and SVG/HTML previews and coding agents in tabs of their own.

## How it's meant to be used

Each project is a tab along the top (`+` opens one, `×` closes it). Inside it, the tabs along the bottom are full screen: Neovim, then a shell, and as many more shells and agents as you like (`+`, Alt-t or Cmd-T for a shell). They're tmux windows, so they're saved and restored with the project. `Space tc` opens Claude in a new tab (already connected, so it sees your selection and shows edits as diffs: `Space aa` / `Space ad`). `Space tx` Codex, `Space to` OpenCode, `Space tk` Kilo, `Space tg` Gemini, `Space tf` Freebuff, `Space tn` a plain shell. An agent's tab shows its session's name. Every press starts another one; all keep running in the background. Files an agent changes reload in Neovim within a second; Alt-g shows everything it changed as side-by-side diffs (Alt-g again to go back). Click a tab or press Alt-1 to get back to Neovim.

## Setup

Run `install.sh` at the top of this repo (see the repo's README). It links this folder to `~/.config/nvim` and installs the plugins, parsers and language servers. SDKs for the languages you use (Flutter, Rust, Xcode, Node, Python, Terraform) are your own installs.

## Where things live

| Area | Files |
|---|---|
| Plugins | `lua/plugins/*.lua`, one file per area |
| Language servers | `lua/configs/lspconfig.lua` (Dart: `plugins/flutter.lua`, Rust: `plugins/rust.lua`) |
| Formatting | `lua/configs/conform.lua` |
| Debuggers | `lua/configs/dap.lua` |
| Keys | `lua/mappings.lua`, plus `after/ftplugin/{dart,rust,slint}.lua` |
| Shell and agent tabs | `lua/configs/terminals.lua` (keys), `tmux/tmux.conf` and `bin/tab` at the top of the repo |
| Treesitter parsers | `lua/configs/treesitter_parsers.lua` |
| Line numbers coloured by mode | `local-plugins/nvim-color-line-numbers-by-mode` |

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
| Alt-g (anywhere, even in an agent terminal) | show / hide all git changes, side by side (like VS Code's Source Control) |
| `gd` in any terminal (or tmux prefix g) | the same view on its own, for whatever repo you are in; `gd main` compares with a branch; `q` quits |
| `Space gv` / `Space gV` | open / close the same changes view |
| `Space gf` / `Space gF` | this file's / the project's git history |
| `Space gg` / `Space gh` / `Space gb` | lazygit / preview hunk / blame line |
| `]h` `[h`, `Space gs` / `Space gu` / `Space gw` | next/previous change, stage / undo change / word diff |
| `Space tn`, Alt-t, Cmd-T or `+` | new full-screen shell tab |
| Alt-. / Alt-, / `Space tl` / `Space tr` | next / previous / pick / rename terminal |
| click a tab (top: projects, bottom: this project's tabs) | switch to it; `×` on a bottom tab closes that terminal, `× project` closes the project and all its tabs (both ask), `+ project` opens one; right-click a bottom tab to rename it |
| `Space tc` `tx` `to` `tk` `tg` | new Claude, Codex, OpenCode, Kilo, Gemini tab |
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

## Opening projects

Each project gets a tmux session, all in one tmux, shown in a tab of its own along the top: window 1 runs Neovim, window 2 "shell 1" (Alt-1 / Alt-2). Every terminal starts in the project folder. Opening a project again returns to its running session. tmux saves every project every 5 minutes and restores them all when it next starts, agents continuing their last conversation; prefix Ctrl-s / Ctrl-r save / restore by hand.

- Finder: right-click a folder → Quick Actions → **Open in Neovim**, or drop a folder on kitty's Dock icon. With kitty open, the project joins it; otherwise kitty opens. Source: `macos/Open in Neovim.workflow` in this repo.
- Terminal: `t` opens the folder you're in (`t <dir>` another one); `p` fuzzy-picks from every project under `~/Projects`, `~/Developer`, `~/code` and `~/Desktop` (or the folders listed one per line in `~/.config/agent-workspace/roots`).
- Inside tmux: `+` at the top, or prefix (Ctrl-Space) then `P` or `s`, picks a project in a popup and switches to it.

The scripts are in `bin/` at the top of this repo, linked into `~/.local/bin`.
