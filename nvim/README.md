# Neovim config (NvChad, macOS)

NvChad v2.5 on Neovim 0.12, set up for Flutter/Dart (plus the iOS and Android folders: Swift, Objective-C, Kotlin, Gradle, XML, Podfile), Rust (Bevy, Slint), Swift, Python, TypeScript/JavaScript, Terraform (Google Cloud), Docker, YAML/JSON/TOML (GitHub Actions, CloudFormation), with image and SVG/HTML previews and coding agents in tabs of their own.

## How it's meant to be used

Each project is a tab along the top (`+ Project` opens one, its icon closes it). Inside it, the tabs along the bottom are full screen: Neovim, then a shell, and as many more shells and agents as you like (`+ Shell`, Alt-t for a shell). They're saved with the project and come back when you open it. `Space tc` opens Claude in a new tab (already connected, so it sees your selection and shows edits as diffs: `Space aa` / `Space ad`). `Space tx` Codex, `Space tp` Copilot, `Space tg` Gemini, `Space td` DeepSeek, `Space to` OpenCode, `Space tk` Kilo, `Space tf` Freebuff, `Space tu` Cursor, `Space ta` Aider, `Space tm` Amp, `Space tq` Qwen (`agvim agents` shows which are installed), `Space tn` a plain shell. An agent's tab shows its session's name. Every press starts another one; all keep running in the background. Files an agent changes reload in Neovim within a second; Alt-g shows everything it changed as side-by-side diffs (Alt-g again to go back). Click a tab or press Alt-1 to get back to Neovim.

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
| Shell and agent tabs | `lua/configs/terminals.lua` (keys), `tmux/tmux.conf` and `lib/tab` at the top of the repo |
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
| `gd` or `Space gd`, `Space gr`, `Space gi`, `Space fs` | definition, references, implementations, workspace symbols |
| `K` or `Space I`, `Space ca`, `Space rs` | hover, code action, rename |
| `Space fm` | format (also on save for Dart, Rust, Lua, Slint, Terraform; `:FormatToggle`) |
| `Space qq` / `Space qt` / `Space qv` | all problems / line problem / inline problem text |
| `Space qb` / `ql` / `qf`, `Space cs` / `cl` | this file's problems / location list / quickfix list, symbols / LSP references (Trouble) |
| `]e` / `[e`, `]d` / `[d` | next / previous error, diagnostic |
| `Space ih` | inlay hints |
| `Space rr` | project search and replace (regex) |
| `F5` `F9` `F10` `F11` `Shift-F11` `Shift-F5` | debug: start/continue, breakpoint, over, into, out, stop |
| `Space du` / `Space dh` | debugger UI / evaluate |
| `Space dc` `db` `dd` `dj` `dl` `dk` `de` `dr` | debug: continue, breakpoint, conditional breakpoint, over, into, out, stop, run last |
| `Space Fr` `Fh` `FR` `Fq` `Fd` `Fo` `Fl` `Fe` `Ft` `Fp` | Flutter: run, hot reload, restart, quit, devices, outline, log, emulators, DevTools, pub get |
| `Space Rr` `Rd` `Re` `Rm` `Rc` `dt` | Rust: run, debug, explain error, expand macro, open Cargo.toml, tests |
| `Space sp` | Slint live preview |
| `Space ac` `as` `ab` `aa` `ad` `af` `ar` `aC` | Claude Code: open, send selection, add file, accept/reject diff, focus, resume, continue |
| `Space c-` | insert a comment separator line |
| Ctrl-W in a terminal | leave terminal mode (so it doesn't delete a word there) |
| F13 / F14 / F15 / F16, F19 | Normal / Insert / Visual / Command mode from any mode; in insert mode save, in a terminal type `exit` |
| Alt-g (anywhere, even in an agent terminal) | show / hide all git changes, side by side (like VS Code's Source Control) |
| `agvim diff` in any terminal (or tmux prefix g) | the same view on its own, for whatever repo you are in; `agvim diff main` compares with a branch; `q` quits |
| `Space gv` / `Space gV` | open / close the same changes view |
| `Space gf` / `Space gF` | this file's / the project's git history |
| `Space gg` / `Space gh` / `Space gb` | lazygit / preview hunk / blame line |
| `]h` `[h`, `Space gs` / `Space gu` / `Space gw` | next/previous change, stage / undo change / word diff |
| Tab or Alt-l, Alt-n / Alt-p, Alt-e | accept an AI suggestion, next / previous, dismiss (`agvim ai` chooses the source) |
| `Space tn`, Alt-t or `+ Shell` | new full-screen shell tab |
| Alt-. / Alt-, / `Space tr` | next / previous / rename terminal |
| Cmd-1..9 (Cmd-1 Cmd-2 quickly for 12); Cmd-0; Cmd-B / Cmd-O then a number. In other terminals Ctrl-Space then the number, 0, b or o | go to the one showing that number on the row whose numbers are lit (tabs at first); light the next row (tabs, worktrees, projects; clicking a tab in a row lights that row too); go to that worktree / project |
| double-click a tab, project or worktree | it gets a `*`: Left / Right move it, Delete closes it (asks), r renames it (not a worktree); any other key is done |
| click a tab (top: projects, middle: worktrees, bottom: this project's tabs, which in a worktree start with its branch) | switch to it; the icon on a bottom tab closes that terminal, on a project at the top closes it and all its tabs (both ask); `+ Project` at the top opens a project and `+ Shell` a console; `+ Worktree` and `Merge` in the middle row; right-click a tab to rename it or change its colour; drag, double-click then Left / Right, or Alt-Shift-Left / Right to move it; with too many to fit, `<` `>` or the wheel on a bar move along it |
| `Space a>` / `Space ae` | send the selection (or the change or line here) / the errors here to the agent you used last, unsent |
| `Space tR` / `Space tS` | ask that agent to `/resume-session` / add skills and commands to this project |
| Alt-Shift-B, tmux prefix a, prefix m | new worktree, every running agent, merge this worktree |
| `Space tc` `tx` `tp` `tg` `td` `to` `tk` `tf` `tu` `ta` `tm` `tq` | new Claude, Codex, Copilot, Gemini, DeepSeek, OpenCode, Kilo, Freebuff, Cursor, Aider, Amp, Qwen tab |
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

Opening a `.png`, `.jpg`, `.gif` or `.webp` shows the picture (in terminals with the kitty graphics protocol; works inside tmux with `allow-passthrough on`). `.svg` opens as editable XML: `Space pi` shows it rendered, `Space pv` opens it in the browser where SMIL animations play, updating as you type. HTML previews in the browser too and refreshes on save.

## Flutter iOS folder

Swift and Objective-C in `ios/` need to know the Xcode project. Once per app: build it once (`fvm flutter build ios --debug --no-codesign` or in Xcode), open a file in `ios/`, run `:XcodeBuildServer`. It writes `ios/buildServer.json`; keep that out of git.

## Opening projects

Each project is a tab along the top: a name and one or more folders, saved in `saved-projects/` of the repo. Inside it, window 1 runs Neovim, then lazygit (both come back every time you open the project, even if you closed them), then "shell 1", in the first folder (Alt-1, Alt-2...), and each other folder gets a Neovim tab of its own. Closing a project or its terminal window saves its tabs and stops them; opening it again brings them back, agents continuing their last conversation.

- Finder: right-click a folder → **New AgVim Project** or **Add to AgVim Project**. Source: `macos/finder/` in this repo.
- Inside the workspace: `+ Project` at the top, or prefix (Ctrl-Space) then `P` or `s`: open a saved project, make a new one from any folder, or add a folder to this one. `+ Shell` opens a console that isn't a project.
- Terminal: `agvim open` opens the picker, `agvim open <dir>` a folder. The picker also lists every project folder under `~/Projects`, `~/Developer`, `~/code` and `~/Desktop` (or the folders listed one per line in `~/.config/agvim/roots`).

The scripts are in `lib/` at the top of this repo, behind the `agvim` command.
