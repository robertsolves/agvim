# Setting up agent-workspace (for coding agents)

You are installing this setup on the user's Mac, or changing it. Follow the steps in order. Each step says how to check it worked.

## Install

1. **Check the Mac.** Run `uname` and `command -v brew`. Expected: `Darwin`, then a path. If it's not macOS, stop and tell the user this setup is macOS only. If `brew` is missing, ask the user to install Homebrew from https://brew.sh. It asks for their password, so they run it themselves.
2. **Get the repo.** If the user already has a clone, work in it. Otherwise run `git clone https://github.com/robertsolves/agent-workspace.git ~/.agent-workspace`.
3. **Tell the user what will change, then run it.** `install.sh` replaces `~/.config/nvim` and `~/.tmux.conf` with links into the repo, and links `open-project`, `t`, `p`, `gd`, `projects` and `tab` into `~/.local/bin`. Anything already there is moved to `<name>.bak-<date>`. Run `./install.sh` from the clone. The language server install takes 5 to 15 minutes, so give it a long timeout or run it in the background.
   - If the user wants to install Homebrew packages themselves, add `--no-brew`.
   - If the Neovim tools step fails, finish the rest with `--no-tools` and see Troubleshooting.
4. **Check the result.**
   - `ls -l ~/.config/nvim ~/.tmux.conf ~/.local/bin/{t,p,gd,open-project,projects,tab}`: each one points into the repo.
   - `nvim --headless "+checkhealth vim.lsp" +qa` exits without errors.
   - `nvim --headless "+lua print(#require('mason-registry').get_installed_package_names())" +qa` prints a number of about 25 or more.
   - `ls ~/Library/Services` lists `Open in Neovim.workflow`.
5. **PATH.** If the installer warned that `~/.local/bin` is not on PATH, tell the user to add `export PATH="$HOME/.local/bin:$PATH"` to `~/.zshrc`. Don't edit their shell files unless they ask you to.
6. **Search folders for `p`.** Ask the user where they keep projects. If it isn't `~/Projects`, `~/Developer`, `~/code` or `~/Desktop`, write those folders one per line to `~/.config/agent-workspace/roots`.
7. **Tell the user about the steps only they can do:**
   - If the Quick Action isn't in Finder's right-click → Quick Actions menu, turn it on in System Settings → Keyboard → Keyboard Shortcuts → Services → Files and Folders → **Open in Neovim**.
   - Open kitty once, so macOS asks for any permissions it needs.
   - For Swift in a Flutter app's `ios/` folder: build the app once, then run `:XcodeBuildServer` in a file there.
   - SDKs for the languages they use (Flutter, Rust via rustup, Xcode, Node, Python, Terraform) are their own installs. `install.sh` lists the missing ones at the end.

## Troubleshooting

- **Mason fails on basedpyright or debugpy** ("No module named pip", ensurepip errors): Homebrew's Python 3.15 on macOS 26 can't create venvs with pip. `install.sh` already puts python3.14, 3.13 or 3.12 first on PATH when it finds one. If none is installed, run `brew install python@3.14` and rerun `./install.sh --no-brew`.
- **Neovim tools hang or time out headless**: run `nvim` once normally and wait for the installs to finish. `:Lazy`, `:Mason` and `:checkhealth` show progress.
- **`brew bundle` fails on kitty or the font**: they were installed some other way. That's fine; the script installs those casks only when it can't find them.
- **Alt keys type special characters**: kitty must include `agent-workspace.conf` (`macos_option_as_alt left`). Restart kitty after installing.
- **Images don't show**: they only work in kitty. Neovim runs two tmux deep (a project's tmux inside the projects bar's), so `nvim/lua/plugins/preview.lua` wraps image data twice; both tmux configs allow passthrough.

## Changing the setup

- Edit files in the repo, not in `~/.config/nvim`. That path is a link into the repo, so both are the same files.
- Keys are listed in `nvim/README.md`. Add new keys there when you add them to `nvim/lua/mappings.lua` or a plugin spec.
- Language servers: add to `nvim/lua/configs/lspconfig.lua` and to the Mason list in `nvim/lua/plugins/lsp.lua`. Parsers: `nvim/lua/configs/treesitter_parsers.lua`.
- `nvim/local-plugins/nvim-color-line-numbers-by-mode` is a copy of github.com/dev-cetera/nvim-color-line-numbers-by-mode with fixes. Edit it here.
- After changing `install.sh`, run `shellcheck install.sh`, then run `./install.sh --no-brew` to check that a second run changes nothing.
- Projects are the tabs of the projects bar along the top: a tmux server of its own (`tmux -L projects`, `tmux/projects.conf`, `bin/projects`) whose windows each attach to one project's session in the user's tmux. kitty runs `projects` on start (`kitty/startup-session.conf`); `bin/open-project` adds a project. Inside a project the tabs along the bottom are full-screen tmux windows (`tmux/tmux.conf`, `bin/tab`, `nvim/lua/configs/terminals.lua`). This repo always opens as a project, so the user changes the setup from inside it; reopening kitty reloads both tmux configs.
- Test tmux changes on separate servers, not the user's running ones: set `TMUX_TMPDIR` to a short empty folder and `HOME` to a scratch folder (so tmux-resurrect doesn't overwrite the user's saved sessions), then simulate clicks by sending SGR mouse sequences (`\e[<0;X;YM`, 1-based) to a pane that runs the client. Export `TMUX_TMPDIR` before any tmux command of the test, including the clean-up: `tmux -L projects kill-server` without it kills the user's bar.
- Anything a tmux binding runs with `run-shell` must print nothing and exit 0. Output or a non-zero exit opens tmux's view mode in the pane, which swallows every key and click until `q`. A prompt there is `confirm-before -b` (returns at once, 0 whatever the answer); other commands get `>/dev/null 2>&1`. After a change, check `#{pane_in_mode}` stays 0 on the test servers.
- Test Neovim changes headless: `nvim --headless "+lua print('ok')" +qa` should print only `ok`.
