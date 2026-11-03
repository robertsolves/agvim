# agent-workspace

A Mac setup for reading code while coding agents write it: Neovim with your code on top and Claude, Codex, OpenCode, Kilo or Gemini in terminals along the bottom. Right-click a folder in Finder to open it, and press Alt-g to see what the agents changed.

- **Neovim** (NvChad) with language servers, completion, formatting and debuggers for Flutter/Dart (plus the iOS and Android folders), Rust (Bevy, Slint), Swift, Python, TypeScript/JavaScript, Terraform, Docker, YAML, JSON and TOML.
- **Tabs**: projects are kitty's tabs along the top. Inside a project, the tabs along the bottom are full screen: Neovim, then as many shells and agents as you want (click `+` or press Cmd-T for a shell). They're tmux windows, so they're saved and restored with the project. Claude starts connected to Neovim, so it sees your selection and shows its edits as diffs.
- **Git changes**: Alt-g from anywhere, even inside an agent's terminal, shows every changed file side by side. `gd` does the same from any terminal.
- **Previews**: PNG, JPG, GIF and WebP inside Neovim (kitty graphics), SVG rendered in a float, and animated SVG, HTML and Markdown live in the browser.
- **Projects in one tmux**: each project is a session that keeps running when you close the window, and every terminal starts in its folder. Everything is saved every 5 minutes and comes back by itself when tmux next starts (after closing kitty, a crash or a reboot), agents included: each continues its last conversation. Prefix is Ctrl-Space.
- **Opening projects**: right-click a folder → Quick Actions → **Open in Neovim**, or drop a folder on kitty's Dock icon. Either adds it to the tmux you have open. `t` opens the folder you're in, `p` fuzzy-picks a project.
- **Closing**: the `×` on a bottom tab closes just that terminal; `× project` on the right closes the project and all its terminals (both ask first). `+ project` picks a project to open. Right-click a bottom tab to rename it. Closing a project's kitty tab (Cmd-W) leaves it running in tmux.

## Install

macOS with [Homebrew](https://brew.sh):

```sh
curl -fsSL https://raw.githubusercontent.com/robertsolves/agent-workspace/main/install.sh | bash
```

That clones this repo to `~/.agent-workspace` and runs `install.sh`, which:

1. Installs the tools in the `Brewfile`, plus kitty and JetBrainsMono Nerd Font if they're missing.
2. Links `nvim/` to `~/.config/nvim`, `tmux/tmux.conf` to `~/.tmux.conf`, and `bin/*` into `~/.local/bin`. It also adds `kitty/agent-workspace.conf` to kitty's config. Anything already there is moved to `<name>.bak-<date>`, never deleted.
3. Installs tmux's plugins and the Finder Quick Action.
4. Installs Neovim's plugins, treesitter parsers and language servers.

To install from a clone instead, run `./install.sh`. `--no-brew` skips Homebrew and `--no-tools` skips step 4. Running it again is safe. To update, `git pull` in the clone: your config links into it.

Install the SDKs you use yourself: Flutter (fvm projects are picked up), Rust via rustup (`rustup component add rust-analyzer clippy`), Xcode, Node, Python and Terraform.

Coding agents set this up from [AGENTS.md](AGENTS.md).

## Use

1. Right-click a project folder → Quick Actions → **Open in Neovim**. kitty opens it as a tab along the top, with Neovim and a shell as tabs along the bottom. Do the same with another folder and it opens as another tab at the top.
2. `Space tc` starts Claude in a new tab. `Space tx` starts Codex, `Space to` OpenCode, `Space tk` Kilo and `Space tg` Gemini. Each press starts another one. Alt-t (or Cmd-T, or `+`) adds a shell tab. Click a tab, or press `Alt-.` / `Alt-,` or Alt-1..9, to switch.
3. Files an agent changes reload above within a second. Alt-g shows all changes; Alt-g again goes back.
4. Close kitty whenever you like: the projects keep running in tmux. Open kitty again (Dock, Spotlight) and every project is back as a tab. After a crash or reboot, opening kitty restores them first, agents included (or prefix Ctrl-r).

Every key: [nvim/README.md](nvim/README.md). The tmux keys are at the top of [tmux/tmux.conf](tmux/tmux.conf).

## What's where

| Folder | What it is | Linked to |
|---|---|---|
| `nvim/` | Neovim config | `~/.config/nvim` |
| `tmux/tmux.conf` | tmux config | `~/.tmux.conf` |
| `kitty/agent-workspace.conf` | Left Option acts as Alt; projects as tabs on top; Cmd-T opens a shell tab in tmux | included from `~/.config/kitty/kitty.conf` |
| `kitty/launch-actions.conf` | A folder dropped on kitty's Dock icon opens as a project | `~/.config/kitty/launch-actions.conf` |
| `kitty/startup-session.conf` | Opening kitty opens a tab for every project (`open-project --all`) | `~/.config/kitty/startup-session.conf` |
| `bin/` | `open-project`, `t`, `p`, `gd`, `tab` (the tabs along the bottom) | `~/.local/bin/` |
| `macos/Open in Neovim.workflow` | Finder Quick Action | copied to `~/Library/Services/` |

`p` searches `~/Projects`, `~/Developer`, `~/code` and `~/Desktop`. To change that, list your own folders one per line in `~/.config/agent-workspace/roots`.
