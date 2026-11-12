# AgVim (for coding agents)

This repo is AgVim itself, usually open as the first tab of the running workspace, so changes show up for the user as you make them. To change it, follow "Changing the setup" below (the `develop-agvim` skill); to publish it, the `release-agvim` skill. To install it on a user's Mac, follow the steps here.

You are installing this setup on the user's Mac, or changing it. Follow the steps in order. Each step says how to check it worked.

## Install

1. **Check the Mac.** Run `uname`. Expected: `Darwin`. If it's not macOS, stop and tell the user this setup is macOS only.
2. **Get the repo.** If the user already has a clone, work in it. Otherwise run `git clone https://github.com/robertsolves/agvim.git ~/.agvim`.
3. **Tell the user what will change, then run it.** `install.sh` replaces `~/.config/nvim` and `~/.tmux.conf` with links into the repo, and links `agvim` into `~/.local/bin`. Anything already there is moved to `<name>.bak-<date>`. Run `./install.sh` from the clone. The language server install takes 5 to 15 minutes, so give it a long timeout or run it in the background.
   - If the user wants to install Homebrew packages themselves, add `--no-brew`.
   - If the Neovim tools step fails, finish the rest with `--no-tools` and see Troubleshooting.
4. **Check the result.**
   - `ls -l ~/.config/nvim ~/.tmux.conf ~/.local/bin/agvim`: each one points into the repo.
   - `nvim --headless "+checkhealth vim.lsp" +qa` exits without errors.
   - `nvim --headless "+lua print(#require('mason-registry').get_installed_package_names())" +qa` prints a number of about 25 or more.
   - `pluginkit -m -i io.github.robertsolves.agvim.finder.extension` starts with `+`.
5. **PATH.** `install.sh` adds `~/.local/bin` to `~/.zshrc` if it's missing (a line ending in `# agvim`); `uninstall.sh` removes it.
6. **Search folders for the picker.** Ask the user where they keep projects. If it isn't `~/Projects`, `~/Developer`, `~/code` or `~/Desktop`, write those folders one per line to `~/.config/agvim/roots`.
7. **Tell the user about the steps only they can do:**
   - If New AgVim Project and Add to AgVim Project aren't in Finder's right-click menu, turn on agvim Finder in System Settings → General → Login Items & Extensions → Finder.
   - Run `agvim` in their terminal and choose **Open project**. The AgVim icon opens kitty, set up. In another terminal, they set Option to act as Alt and JetBrainsMono Nerd Font themselves (see `docs/GUIDE.md`).
   - For Swift in a Flutter app's `ios/` folder: build the app once, then run `:XcodeBuildServer` in a file there.
   - SDKs for the languages they use (Flutter, Rust via rustup, Xcode, Python, Terraform) are their own installs. `install.sh` lists the missing ones at the end. The app and all its tools are not.

## Troubleshooting

- **Mason fails on basedpyright or debugpy** ("No module named pip", ensurepip errors): Homebrew's Python 3.15 on macOS 26 can't create venvs with pip. `install.sh` and Neovim (`nvim/lua/plugins/lsp.lua`) put python3.14, 3.13 or 3.12 first on PATH for Mason when they find one, and the Brewfile installs python@3.14.
- **Neovim tools hang or time out headless**: run `nvim` once normally and wait for the installs to finish. `:Lazy`, `:Mason` and `:checkhealth` show progress.
- **`brew bundle` fails on the font**: it was installed some other way. That's fine; the script installs that cask only when it can't find it.
- **Alt keys type special characters**: the terminal must send Option as Alt. `docs/GUIDE.md` lists the setting for kitty, iTerm2 and Terminal.
- **Images don't show**: they need a terminal with the kitty graphics protocol, such as kitty or Ghostty. Neovim runs two tmux deep (a project's tmux inside the projects bar's), so `nvim/lua/plugins/preview.lua` wraps image data twice; both tmux configs allow passthrough.
- **Tabs look plain, or nothing comes back after a restart, after moving the clone**: the links still point at the old folder (`ls -l ~/.tmux.conf`). Rerun `./install.sh --no-brew --no-tools` from the new one.

## Changing the setup

- **After every change, run `agvim refresh`** so the user sees it straight away. It reloads both tmux configs and restarts each running Neovim with the same files and splits; shells and agents keep running, and `lib/` and `bin/` changes are live already. Only `macos/kitty.conf` needs a new AgVim window, and `macos/finder/` or `install.sh` changes need `./install.sh --no-brew --no-tools`.
- `bin/agvim` is the only command on PATH: every feature is a subcommand there, listed in its help and `docs/GUIDE.md`. Folders default to `.` and projects to the current one, with `-p` to pick; `lib/` holds the scripts behind it, and tmux, Neovim and Finder call them as `~/.local/bin/agvim _<script>`.
- Edit files in the repo, not in `~/.config/nvim`. That path is a link into the repo, so both are the same files.
- Keys are listed in `nvim/README.md`. Add new keys there when you add them to `nvim/lua/mappings.lua` or a plugin spec.
- The website is `docs/index.html`, deployed by `.github/workflows/site.yml` when `docs/` changes on `main`. Add new dependencies to its lists.
- AI autocomplete sources: add a row to `lib/ai-providers.tsv`. OpenAI-compatible services need no code.
- Releases: `agvim release X.Y.Z` (`macos/release.sh`, `.github/workflows/release.yml`). Each launch updates to the newest release (`lib/auto-update`), so changes reach people only when released.
- Agents: add a row to `lib/agents.tsv` (key, command, how to continue, where to get it). Only use a resume command you've confirmed in its docs; otherwise `-`.
- Language servers: add to `nvim/lua/configs/lspconfig.lua` and to the Mason list in `nvim/lua/plugins/lsp.lua`. Parsers: `nvim/lua/configs/treesitter_parsers.lua`.
- `nvim/local-plugins/nvim-color-line-numbers-by-mode` is a copy of github.com/dev-cetera/nvim-color-line-numbers-by-mode with fixes. Edit it here.
- After changing `install.sh` or `uninstall.sh`, run `shellcheck` on it, then run `./install.sh --no-brew` to check that a second run changes nothing. Anything `install.sh` adds, `uninstall.sh` must remove. Test `uninstall.sh` only with `HOME` and `TMUX_TMPDIR` set to scratch folders, from a copy of the repo: it deletes what it finds.
- Projects are the tabs of the projects bar along the top: a tmux server of its own (`tmux -L projects`, `tmux/projects.conf`, `lib/projects`) whose windows each attach to one project's session in the user's tmux. A saved project is a file in `saved-projects/` (`lib/project`), one folder per line; `+ Shell` makes a console with no such file. Inside a project the tabs along the bottom are full-screen tmux windows (`tmux/tmux.conf`, `lib/tab`, `nvim/lua/configs/terminals.lua`). The user runs `agvim` in any terminal, which reloads both tmux configs. This repo is always the bar's first tab (`add` in `lib/projects`), with no x, so the setup can be changed and updated from inside. Nothing here may depend on one terminal or change its config: AgVim ships kitty and prefers it, with `macos/kitty.conf` applied only to the windows it opens, and `agvim` works in any terminal. The one exception, which the user chose: an include line in kitty.conf (`lib/kitty-keys`, from `install.sh`; `uninstall.sh` removes it) for the ⌘ keys in `macos/kitty-keys.conf`, so they work in plain kitty too. Every key there is `--when-focus-on 'title:^AgVim\b'`, so it acts only in windows the projects bar titles AgVim; every ⌘ key also has a Ctrl-Space or Alt key for other terminals.
- Closing a project, or the last terminal window showing the bar (the bar's `client-detached` hook), saves its tabs to `saved-projects/.tabs/` and stops it. A bar tab starts its project only when first shown (`projects run`). An agent tab comes back as its own conversation when its agent can resume one by id (`by_id` in `lib/project`, with how `session_of` finds the id); add a new agent there only with a flag you've confirmed in its help.
- Agent features: `lib/attention` (the needs-you dot; Claude's hooks are `lib/claude-settings.json`, others ring the bell), `lib/worktree` (the middle row of the bar), `lib/send`, `lib/running`, `lib/init`, `lib/skills` (reuses a source's own `install.sh`, as agent-commands has, and never touches an agent's settings outside the project), `lib/colours` (tab colours, from Neovim's theme via `configs/tab_colours.lua`). Tests: `tests/agents.sh`.
- tmux options on a session need a target ending in a colon: `set-option -t "=$s:"`. Without it tmux reads `=$s` as a window and fails.
- In the zsh scripts, never name a variable `path`: it's tied to `PATH`.
- Test tmux changes on separate servers, not the user's running ones: set `TMUX_TMPDIR` to a short empty folder and `HOME` to a scratch folder, and run a copy of the repo (saved projects live in the clone) with stubs for `nvim` and, if the test can reach it, `brew`, first on PATH. Never run `install.sh` in a test without `--no-brew` unless `command -v brew` is a stub: a scratch `HOME` doesn't protect Homebrew, then simulate clicks by sending SGR mouse sequences (`\e[<0;X;YM`, 1-based) to a pane that runs the client. Export `TMUX_TMPDIR` before any tmux command of the test, including the clean-up: `tmux -L projects kill-server` without it kills the user's bar. If that folder is gone, tmux quietly uses `/tmp`'s, the real one, so the tests put `tests/tmux-guard` first on PATH as `tmux`; give each parallel test or agent its own folder, and never clean up others' with a glob. Stop a test's servers by their socket files (`tmux -S`), never `tmux -L` with a folder that may be gone. A test that runs Neovim with the real `HOME` sets `XDG_STATE_HOME` to its folder, so its session files can't replace yours.
- Anything a tmux binding runs with `run-shell` must print nothing and exit 0. Output or a non-zero exit opens tmux's view mode in the pane, which swallows every key and click until `q`. A prompt there is `confirm-before -b` (returns at once, 0 whatever the answer); other commands get `>/dev/null 2>&1`. After a change, check `#{pane_in_mode}` stays 0 on the test servers.
- `install.sh` and `macos/finder/build.sh` register the Finder extension for the real user even with a scratch `HOME`: after testing them, run `macos/finder/build.sh` from the real clone.
- `macos/bundle.sh` builds `dist/AgVim.app` and `.dmg` from the tracked and new files. The app holds no tools: it opens a terminal (`macos/app/launcher`, `lib/terminal`); its first launch runs `macos/app/first-run`.
- Test Neovim changes headless: `nvim --headless "+lua print('ok')" +qa` should print only `ok`.
