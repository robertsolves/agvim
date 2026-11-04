---
name: develop-agentnv
description: How to change AgentNV from inside it - where things live, how to show the user a change straight away with agentnv refresh, and how to test without touching their running workspace or Homebrew. Use for any change to this repo.
---

# Develop AgentNV

You're usually running inside the workspace you're changing. Everything the user has open depends on these files.

1. Read "Changing the setup" in `AGENTS.md`. New features are subcommands of `bin/agentnv`, listed in its help and `docs/GUIDE.md`.
2. Make the change in this repo. Never edit `~/.config/nvim` or `~/.tmux.conf`: they're links into it.
3. Run `tests/run.sh`, and add to `tests/` when a behaviour is new.
4. Run `agentnv refresh`, then tell the user what to look at. It keeps shells and agents running and restarts Neovim with the same files. Exceptions: `macos/kitty.conf` needs a new AgentNV window; `macos/finder/` and `install.sh` need `./install.sh --no-brew --no-tools`.

## Don't break the running workspace

- Test only on separate servers: `TMUX_TMPDIR` and `HOME` set to scratch folders, a copy of the repo, stubs for `nvim`, `open` and `brew` first on PATH. `tests/` shows how.
- A scratch `HOME` doesn't protect Homebrew or the Finder extension. Never run `install.sh` without `--no-brew` unless `command -v brew` is a stub. After testing `install.sh`, run `macos/finder/build.sh` from the real clone.
- Anything a tmux binding runs with `run-shell` must print nothing and exit 0, or the pane locks up in view mode.
- Moving a script breaks the bindings of the running session until `agentnv refresh`, so refresh straight after.
- In zsh scripts, never name a variable `path`: it empties `PATH`.
- Never put AgentNV's folders ahead of the user's `PATH`: append them.
- Never write a file you're reading in the same expression, such as Python's `open(f,'w').write(open(f).read())`: it empties the file.

## Keep it portable

It runs on anyone's Mac and in any terminal. No paths, names or settings from one machine, and never edit a terminal's config: `macos/kitty.conf` applies only to the windows AgentNV opens.
