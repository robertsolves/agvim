# agent-workspace

A Mac setup for reading code while coding agents write it: Neovim with your code on top and Claude, Codex, OpenCode, Kilo or Gemini in terminals along the bottom. Right-click a folder in Finder to open it, and press Alt-g to see what the agents changed.

- **Neovim** (NvChad) with language servers, completion, formatting and debuggers for Flutter/Dart (plus the iOS and Android folders), Rust (Bevy, Slint), Swift, Python, TypeScript/JavaScript, Terraform, Docker, YAML, JSON and TOML.
- **Terminal panel**: a bottom panel with as many shells and agents as you want, as tabs or side by side. Claude starts connected to Neovim, so it sees your selection and shows its edits as diffs.
- **Git changes**: Alt-g from anywhere, even inside an agent's terminal, shows every changed file side by side. `gd` does the same from any terminal.
- **Previews**: PNG, JPG, GIF and WebP inside Neovim (kitty graphics), SVG rendered in a float, and animated SVG, HTML and Markdown live in the browser.
- **tmux**: each project gets a session that keeps running when you close the window. Prefix is Ctrl-Space.
- **Opening projects**: right-click a folder → Quick Actions → **Open in Neovim**, `t` for the folder you're in, or `p` to fuzzy-pick a project.

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

1. Right-click a project folder → Quick Actions → **Open in Neovim**. kitty opens a tmux session with Neovim, and a shell is already in the panel at the bottom.
2. `Space tc` starts Claude in the panel. `Space tx` starts Codex, `Space to` OpenCode, `Space tk` Kilo and `Space tg` Gemini. Each press starts another one. `Alt-.` and `Alt-,` switch between them, and Ctrl-` hides or shows the panel.
3. Files an agent changes reload above within a second. Alt-g shows all changes; Alt-g again goes back.

Every key: [nvim/README.md](nvim/README.md). The tmux keys are at the top of [tmux/tmux.conf](tmux/tmux.conf).

## What's where

| Folder | What it is | Linked to |
|---|---|---|
| `nvim/` | Neovim config | `~/.config/nvim` |
| `tmux/tmux.conf` | tmux config | `~/.tmux.conf` |
| `kitty/agent-workspace.conf` | Left Option acts as Alt | included from `~/.config/kitty/kitty.conf` |
| `bin/` | `open-project`, `t`, `p`, `gd` | `~/.local/bin/` |
| `macos/Open in Neovim.workflow` | Finder Quick Action | copied to `~/Library/Services/` |

`p` searches `~/Projects`, `~/Developer`, `~/code` and `~/Desktop`. To change that, list your own folders one per line in `~/.config/agent-workspace/roots`.
