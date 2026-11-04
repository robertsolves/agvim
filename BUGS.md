# Bugs found in AgVim

A review of the whole repo on 2026-11-04: `bin/agvim`, `lib/`, both tmux configs, the Neovim config, `install.sh`, `uninstall.sh` and `macos/`. Nothing here is fixed yet. Each entry says where the bug is, what goes wrong, and how to see it.

Most of these come from reading the code. The ones marked **(checked)** were also run on Linux with zsh and a scratch tmux server. The tmux here is 3.4, older than AgVim needs, so nothing that depends on tmux's behaviour was checked end to end.

Severity: **High** means lost work or a broken install, **Medium** means a feature does the wrong thing in normal use, **Low** means an edge case, a rough edge, or wrong docs.

---

## High

### 1. Closing the last AgVim window kills tmux sessions that aren't AgVim's
`lib/projects:128-137`, `tmux/projects.conf:39`

When the last window showing the bar closes, `projects stop` runs `save-all` and then `work kill-server`, which stops the user's whole default tmux server. The bar only gets tabs for the sessions that existed when it started (`lib/projects:80-82`), and `.open` only lists the bar's tabs. So a session the user starts afterwards in another terminal (`tmux new -s scratch`, which now uses AgVim's `~/.tmux.conf`) is killed along with every program in it. Its tabs are saved to `.tabs/scratch`, but `agvim continue` never brings it back because it isn't in `.open`.

How to see it: open AgVim, run `tmux new -s scratch -d 'sleep 9999'` in another terminal, then close the AgVim window. `scratch` is gone, and `agvim continue` doesn't restore it.

### 2. `agvim close` with the bar not running empties "continue where you left off"
`lib/project:265-276` (`close` calls `write_open` with no check)

`write_open` writes `bar list-windows` into `saved-projects/.open` and `.active`. `rename` and `save_all` only call it when the bar is up (`bar has-session`), but `close` always calls it. When the bar isn't running, both files are overwritten with nothing, so the menu's "Continue where you left off" and `agvim continue` lose every project that was open.

How to see it: open two projects, close the AgVim window (which saves `.open`), then run `agvim close -p <one of them>` in a plain terminal. `saved-projects/.open` is now empty.

### 3. If the first launch is offline, `agvim update` and auto-update never work again
`macos/app/first-run:131-140`

When GitHub can't be reached, first-run has already run `git init` and `git remote add`, then gives up and leaves a `.git` with an unborn `main` and every file untracked. Later launches skip this block because `.git` now exists, so it's never tried again. After that:
- `lib/auto-update` exits at once, because `git rev-parse --abbrev-ref HEAD` isn't `main` on an unborn branch.
- `agvim update` fetches and then fails on `git merge --ff-only <tag>` ("untracked working tree files would be overwritten"), and it tells the user their own changes are in the way.

The message "agvim update won't work until it can" suggests it starts working again once the network is back, but it never does.

### 4. Uninstalling deletes Neovim data that was there before AgVim
`uninstall.sh:186-188`

`install.sh` moves `~/.config/nvim` aside and `uninstall.sh` puts it back, but `~/.local/share/nvim`, `~/.local/state/nvim` and `~/.cache/nvim` are never backed up. Uninstall deletes them with `rm -rf`. A user's original config comes back without its plugins, and their persistent undo history, shada (marks, registers, command history), swap files and saved sessions are gone for good. The guide says "Anything the install moved aside comes back", which reads as if nothing of theirs is lost.

---

## Medium

### 5. `agvim ai` restarts every Neovim, and saves every unsaved buffer, even when nothing changed
`bin/agvim:441-444`, `bin/agvim:186`, `lib/project:241-242`

`ai_use` and `ai_apply` are two separate commands, so `ai_apply` runs whatever `ai_use` returns:
- When the key is refused (`ai_use` returns 1, "AI autocomplete stays on …"), every Neovim is still restarted.
- Pressing Esc in the model picker returns 0 with nothing changed, and every Neovim is still restarted.

The restart (`refresh`) sends `:silent! wall | … | restart` to every Neovim in every project, which writes every modified buffer to disk without asking. Changes the user meant to throw away get saved. `refresh` has the same side effect when it's run on purpose, but here nothing visible tells the user that it happened.

### 6. Closing a folder's tab doesn't remove a folder that has been moved or deleted
`lib/project:51-55` (`folder_of`), `lib/project:400`, `bin/agvim:227-231` **(checked)**

`folder_of` turns a path that isn't a folder into its parent: `/x/gone/proj` becomes `/x/gone`. So when the bottom tab's × runs `_project remove <name> <@folder>` for a folder that no longer exists, it removes the parent's path, which isn't in the file, and the real line stays. `agvim remove <path>` can't do it either, because `folder_arg` stops with "no such folder" first. The only way to get rid of a stale folder is to edit the file in `saved-projects/` by hand. Meanwhile `agvim list` keeps showing it, and when it was the only folder the project fails with "has no folders left".

### 7. Renaming a closed project drops it from "continue where you left off"
`lib/project:449-462`

`rename` moves the saved file and its `.tabs` folder, but it only rewrites `.open` and `.active` when the bar is running. When it isn't, `.open` still has the old name. The wizard and `lib/projects` both skip names that have no saved file, so the renamed project silently drops out of "Continue where you left off" and doesn't reopen with `agvim continue`. `delete` handles this case (`lib/project:422-426`), but `rename` doesn't.

### 8. Choosing several folders in Finder opens several windows
`lib/project:350-379`, `lib/open-project:188-196`

`finder_new` calls `new` and then `add` once for each extra folder, and each of those ends in `show`, which runs `open-project --window`. When AgVim isn't open yet, the first call starts a new kitty window with `open -n`. kitty takes a moment to attach to the bar, so `tmux -L projects list-clients` is still empty for the next call, and that call opens another window. Choosing 3 folders and then New AgVim Project (or Add to AgVim Project) can open up to 3 windows of the same workspace.

### 9. The first restored tab of a project starts in the wrong folder
`lib/project:173`

When `restore` rebuilds a closed project, every later tab gets `-c "$where"` (the folder the pane was in), but the first one comes from `new-session … -c "$first"`, which is the project's first folder. A shell in the first tab that was `cd`'d into a subfolder comes back in the project root, and so does a project whose first tab is the Neovim tab of its second folder. For a console, the first tab always comes back in `$HOME`.

### 10. A tab with an empty name corrupts the project's saved tabs
`lib/project:138`, `lib/project:158`, `bin/agvim:392-397` **(checked)**

`save` and `restore` split rows with `IFS=$'\t' read`. Tab is a whitespace character in IFS, so two tabs in a row count as one separator and an empty field disappears: every field after it moves one column left. tmux accepts an empty window name (checked: `rename-window ""`), and `agvim name ""` passes its `[ $# -gt 0 ]` check. After that, the next save writes a row whose layout ends up read as the folder, the folder as the pane, and so on, and the project reopens wrong. The same thing happens to any other field that comes out empty.

### 11. `prefix d`, which the cheat sheet calls "detach", makes the project vanish from the bar
`tmux/tmux.conf:99`, `lib/projects:104`

Each bar tab runs `tmux attach -t =<project>`. Detaching that inner client ends the bar tab's process, so the tab closes, while the project's session keeps running in the background with no tab. The next save then writes `.open` without it. It comes back only when the user opens it again by hand. The cheat sheet at the top of `tmux.conf` lists `prefix d` as an ordinary thing to do.

### 12. The bar can't show a tmux session whose name has characters other than letters, digits, space, `_` and `-`
`lib/projects:80-82`, `lib/projects:100`, `lib/project:65-67`

The bar adds a tab for every session on the user's tmux server, but `projects run` calls `project start`, and `start` calls `check_name`, which stops on any name that `clean` would change. A session the user made themselves (for example `tmux new -s "api@v2"`) gets a tab that says it's closed, then "not a project name", waits 5 seconds and vanishes. Its × doesn't work either, because `project close` makes the same check. Note that the tmux `kill-server` from bug 1 still stops it.

### 13. Ctrl-X in the project picker deletes a project without asking, running or not
`lib/p:85-88`, `lib/p:100-102`

The picker's header says "Ctrl-X forgets a saved project". It runs `project delete`, which also kills the project's tmux session (every shell and agent in it) and deletes its saved tabs, with no confirmation. One wrong key while filtering the list loses a running project. `agvim delete` without `-p` asks first.

### 14. In-Neovim terminals (Claude on Space ac) don't survive `agvim refresh`
`lib/project:242`

The refresh line removes `terminal` from `sessionoptions` and then runs `:restart`. A terminal buffer inside Neovim, such as Claude Code opened with `Space ac` (claudecode.nvim, native provider), doesn't come back after the restart. If Neovim refuses to quit while a job is running, the line stops at that prompt instead. Either way this goes against "agents keep running" in AGENTS.md, which only holds for agents in tmux tabs. I haven't run this, so how it actually fails (the job is killed, or Neovim waits at a prompt) needs a check on a Mac.

---

## Low

### 15. `agvim rename <new>` outside a project stops instead of asking which one
`bin/agvim:337-352`. With a new name and no `-p`, it calls `which_project`, which stops with "not in a project" when run outside a project. The help says rename "asks what it doesn't know", and with no arguments at all it does use the picker.

### 16. `agvim delete <name>` deletes without asking
`bin/agvim:354-364`. The help says delete "asks which, and to be sure, without -p". A name given as a plain argument (`agvim delete work`) skips the question, just like `-p`, and also kills the project if it's running.

### 17. `agvim tab` and `agvim agent` don't work in a `+ Shell` console
`bin/agvim:89-107`. `current()` doesn't count an unsaved `Shell N` console as a project, so `which_project` stops with "not in a project", even though Alt-t and `+ Shell` work there.

### 18. A saved project called "Shell N" collides with the consoles
`lib/project:279-286`, `lib/project:294-312`. `new` accepts the name `Shell 1`. `new_shell` only checks for a running session or a bar tab with that name, so with the project closed, `+ Shell` makes a console called `Shell 1`. From then on it's treated as the saved project, and its tabs are saved over that project's.

### 19. Removing an agent from `agents.tsv` breaks restoring its tabs
`lib/project:165`. A tab saved while that agent was running has `prog=<agent>`. Once the row is gone, `resume[$prog]` is empty and the command becomes `"; true"`, a shell syntax error, so that pane exits at once. When it's the first window of the session, the session dies before the rest are built, and `restore` starts a new one for the next row.

### 20. Splits open in the first folder, not the tab's folder
`tmux/tmux.conf:145-146`. `prefix |` and `prefix -` use `#{session_path}`. In a tab for a project's second folder, or a shell that has `cd`'d somewhere, the split starts in the project's first folder. `lib/tab new` respects `@folder`, so new tabs and splits behave differently.

### 21. Right-click Close on a folder's tab doesn't take the folder out
`tmux/tmux.conf:193`. The menu's Close runs `kill-window` directly. The × on the same tab goes through `lib/tab close`, which also removes the folder from the project. With right-click Close, the folder's tab comes back the next time the project opens.

### 22. Alt-g from a shell always goes to the first folder's Neovim
`tmux/tmux.conf:172`. It jumps to the window named `nvim`. In a second folder's shell, Alt-g opens the diff view of the first folder's repo. If the `nvim` tab has been renamed or closed, it fails with an error.

### 23. Every tab that hasn't been opened yet checks tmux about 3 times a second, for as long as it stays unopened
`lib/projects:97-99`. Every bar tab that hasn't been looked at yet runs `tmux display` every 0.3 s. With ten projects from last time, that's about 33 tmux client processes a second until each one is opened.

### 24. `Space tl` is documented but not mapped
`nvim/README.md:57` lists "`Space tl` … pick … terminal". Nothing maps `<leader>tl`: `mappings.lua` has only `tn`, `tr` and the agent keys, and no agent uses `l`.

### 25. `Space x` and `Space /` wait before doing anything
`nvim/lua/mappings.lua:14`, `nvim/lua/mappings.lua:47-55`, `nvim/lua/plugins/editor.lua:354-359`. NvChad maps `Space x` to close the buffer and `Space /` to toggle a comment (the README lists `Space x`). The added `Space xt`, `xv`, `xx`, `xX`, `xL`, `xQ` and `Space //-` make both of them prefixes, so each one now waits `timeoutlen` before it acts.

### 26. `agvim ai list` says the local free-llm-chain "needs key"
`bin/agvim:431-434`. A source counts as ready only if it's Copilot or has a saved key. `freechain` runs on the user's Mac and needs no key, but it always shows "needs key".

### 27. Keys or URLs with `"` or `\` break the AI requests
`bin/agvim:139`, `lib/ai-test:22-28`, `lib/ai-test:54`. The key goes into a curl config line as `header = "…: <key>"` with no escaping. A key containing `"` or `\` makes curl misread the line, so the check reports the wrong thing.

### 28. A folder path with `#`, `$` or `"` breaks closing that folder's tab
`lib/tab:233-234`. The path is escaped for `'` only, then passed through tmux's `confirm-before` and `run-shell`, which expand `#{…}`/`#X` formats and `$VAR` in double quotes. A folder such as `~/Projects/C#Tools` or one with `$` in its name gets mangled, and the folder isn't taken out.

### 29. A fresh install from the app ends up on `main`, not on the release it was downloaded as
`macos/app/first-run:134-136`. First-run runs `git reset --hard origin/main`, so a new user gets whatever is on `main` that day, unreleased work included. `lib/auto-update` says it "follows releases (version tags), not main, so nobody gets unfinished work". It also means the files on disk no longer match what `install.sh` just installed (for example the Finder extension it built).

### 30. The PATH line in `.zshrc` depends on the PATH the installer was run with
`install.sh:178-187`. It only adds the line when `~/.local/bin` isn't on the PATH of the shell running the installer. Running it from a shell that has it (bash, a parent process, an IDE) skips it, and a new zsh then can't find `agvim`. Users of bash or fish never get the line.

### 31. A failed font or kitty install stops the whole install
`install.sh:100-107`. Under `set -e`, `brew install --cask font-jetbrains-mono-nerd-font` or `brew install --cask kitty` failing (no network, a cask conflict) stops `install.sh` before the Neovim config, the tmux link and the `agvim` command are set up. The other Homebrew steps already continue with a warning (`|| warn`).

### 32. Small ones in the Neovim config
- `nvim/lua/plugins/editor.lua:270-275`: Ctrl-Enter in nvim-tree on an empty line errors, because `get_node_under_cursor()` returns nil and `node.nodes` is read anyway.
- `nvim/local-plugins/nvim-color-line-numbers-by-mode/…/init.lua:129-137`: in modes without a colour (command, terminal), only `LineNr` goes back to the theme, and `CursorLineNr` keeps the colour of the previous mode.
- `nvim/lua/configs/svg_preview.lua:64-67`: every `Space pi` on an SVG leaves a `.svg` and a `.png` in the temp folder.
- `nvim/lua/configs/terminals.lua:215`: Space tr puts the name inside single quotes for tmux, so a name with `'` in it fails.
