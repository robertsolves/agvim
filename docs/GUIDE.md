# AgVim guide

## Open it

Click the AgVim icon on your Desktop. It opens AgVim in kitty, set up with its font, colours and keys for those windows only; your own kitty settings stay as they are. To use another terminal: `agvim terminal iTerm`.

Or type `agvim` in any terminal. It asks what you want to do.

## How it works

**Projects** are the tabs along the top. A project is a name and one or more folders. Use `+ Project` to open one, make one from any folder, or add a folder to the one you're in. `+ Shell` opens a terminal that isn't part of any project. The `agvim` tab is always first, so you can update AgVim from inside it.

**Tabs** inside a project run along the bottom, each full screen: Neovim, lazygit, a shell, and as many more shells and agents as you want. What you closed stays closed, including a project's other folders, which also leave the project. Only lazygit always comes back when you open a project, along with the `agvim` tab. `+ Shell` adds a shell.

**The look**: near-black with silver, based on the dark_horizon theme, in Neovim, the tab bars and shells, with highlighting for Dart and Flutter, Rust, Python, TypeScript, Bash, JSON, Swift, Lua, YAML, TOML, Markdown and more. In Neovim, `Space th` picks another theme, though the silver overrides in `nvim/lua/chadrc.lua` only apply to this one.

**Agents**: AgVim works with Claude, Codex, Copilot, Gemini, DeepSeek, OpenCode, Kilo, Freebuff, Cursor, Aider, Amp and Qwen. Install the ones you use; `agvim agents` shows which are ready and where to get the rest. In Neovim, `Space t` then a key starts one: `c` Claude, `x` Codex, `p` Copilot, `g` Gemini, `d` DeepSeek, `o` OpenCode, `k` Kilo, `f` Freebuff, `u` Cursor, `a` Aider, `m` Amp, `q` Qwen. Claude starts connected to Neovim, so it sees your selection and shows its edits as diffs. DeepSeek uses [DeepSeek TUI](https://github.com/Hmbown/DeepSeek-TUI), a third-party tool.

**AI autocomplete**: suggestions appear as you type. Tab or Alt-l accepts (once you've moved through the completion menu, Tab moves through that instead), Alt-n and Alt-p ask for another, and Alt-e dismisses. It uses GitHub Copilot's free tier by default, which needs a free GitHub sign-in: choose it in the menu to sign in, or to sign in again when it expires. To add your own key, or use something free, choose **AI autocomplete** in `agvim`'s menu, or run `agvim ai`. It works with Claude, OpenAI, Gemini, DeepSeek, Mistral, Grok, Groq, OpenRouter, Together, Fireworks, Cerebras, Kimi, Z.ai and Qwen, with [free-llm-chain](https://github.com/robertsolves/free-llm-chain), and with any OpenAI-compatible service through **Custom endpoint**. It checks a new key straight away, and offers the service's own list of models where it has one; `agvim ai test` checks again later. Keys are stored in `~/.config/agvim/ai`, readable only by you. A paid key is charged for every suggestion, so check your provider's prices. Codex uses an OpenAI API key; a ChatGPT or Codex subscription login can't be used here.

**Closing keeps your work running.** Closing the terminal window leaves every project running in the background, so a busy agent or build carries on; run `agvim` again and choose **Back to what's running** (or `agvim continue`). The `agvim` menu has a switch, **Keep terminals running after closing [on]**, and `agvim keep-running off` does the same: then closing stops everything, like `agvim stop`. The icon on a project saves its tabs and stops it. Either way the tabs are saved as you go, so after a restart or a crash opening a project brings them back with what shells last printed and the files and splits Neovim had, and agents that can continue their last conversation do (Amp and Qwen start fresh). A project only starts when you first look at its tab.

After a stop, other programs, such as a dev server, come back as a shell, so start them again. Saved shell output can include anything you printed. It stays on your Mac in `saved-projects/.tabs`, readable only by you.

**Tabs you can tell apart**: each tab's name has a colour of its own from the theme, and the icon next to it closes it. Right-click a tab to rename it, give it another colour, move it or close it; drag it, or press Alt-Shift-Left / Right, to move it. Projects at the top work the same way.

**Working with agents**:

- **A dot when an agent needs you.** A tab whose agent is waiting for an answer, or has finished, shows a dot, and so does its project at the top. Looking at it clears it. If AgVim isn't the window in front, you get a notification too. Claude says exactly when (its hooks, set up for you); Codex and other agents that ring the terminal bell when they finish show it as well.
- **Worktrees: a branch in a folder of its own.** The row under the projects lists `main` and each worktree of the project you're looking at. `+ Worktree` (or Alt-Shift-B, or `agvim worktree <name>`) makes a new branch in its own folder, with its own tabs, and can start an agent there, so several agents can work at once without touching each other's files. Click one to show its tabs. **Merge** shows what changed and merges it into the branch it came from, squashes it into one commit, or pushes it and opens a pull request. If the two changed the same lines, it offers to ask the worktree's agent to sort that out. The icon closes it, asking first if work would be lost. The folders are kept in `~/.local/share/agvim/worktrees`, outside your repo; files listed in a `.worktreeinclude` file (such as `.env`) are copied in. Alt-g in a worktree shows everything since it branched off.
- **Send things to an agent.** In Neovim, `Space a>` puts the selection, or the change or line under the cursor, into the prompt of the agent you used last, with the file and line numbers, and shows its tab, unsent; `Space ae` sends the errors on that line. From a shell, `make test 2>&1 | agvim send` does the same with any output. It works for every agent.
- **Every running agent.** Prefix a (Ctrl-Space then a), or `agvim agents --running`, lists the agents running in every project and worktree, what they're doing and how many files they changed. Enter goes there.
- **An AGENTS.md for your project.** `agvim init` writes one with the build, test and lint commands it finds, plus a CLAUDE.md and GEMINI.md that point to it, and never overwrites a file. `agvim init --agent` then asks your agent to fill in the rest.
- **Skills and commands from a library.** `agvim skills` (or `Space tS`) lists skills and slash commands from [agent-commands](https://github.com/robertsolves/agent-commands), dart-agent-kit and any source you add; Tab marks several, Enter adds just those to the project, set up for every agent it uses. Nothing is added unless you choose it. `Space tR` asks your agent to `/resume-session`, once you've added that command.

**Finder**: right-click a folder for **New AgVim Project**, **Add to AgVim Project** and **Copy Directory**, which copies its path. If they're missing, turn on agvim Finder in System Settings → General → Login Items & Extensions → Finder.

## Keys

| Key | What it does |
|---|---|
| Alt-1..9, `Alt-.`, `Alt-,` | go to a tab, next, previous |
| Alt-t | new shell tab |
| Alt-Shift-Left / Right | move this tab |
| Alt-Shift-B | new worktree |
| Ctrl-Space then a / m | every running agent / merge this worktree |
| Alt-Shift-[ / ] | previous / next project |
| Alt-g | every git change, side by side; again to go back |
| `Space` then wait | every Neovim key |

When a bar has more tabs than fit, it scrolls to keep the current one in view: click `<` or `>`, or use the mouse wheel on it. Rename a tab with `agvim name <text>` in it, or right-click it. A name you give stays, even when an agent runs there.

More: [nvim/README.md](../nvim/README.md), and the top of [tmux/tmux.conf](../tmux/tmux.conf).

In AgVim's kitty windows, the **AgVim** menu in the Mac's menu bar has the main actions, Cmd-T opens a shell tab and Cmd-Shift-[ / ] switch projects. Alt keys need the terminal to send Option as Alt, which those windows do. If you type `agvim` in another terminal, turn it on yourself: in iTerm2 under Profiles → Keys → Left Option key → Esc+, in Terminal under Settings → Profiles → Keyboard → Use Option as Meta key.

## Commands

Type `agvim` alone and it asks what you want to do. Everything also works directly. A folder defaults to where you are, and a project to the one you're in; `-p` picks another.

```sh
# Projects
agvim add .                  # this folder into the project you're in, or a new one
agvim add . -p work          # this folder into "work", made if needed
agvim new ~/code/app -n app  # a folder as a new project
agvim open ~/code/app        # a folder as a project
agvim open -p work           # a project by name
agvim open                   # pick one
agvim close -p work          # save it and stop its tabs
agvim remove . -p work       # take a folder out
agvim rename new-name -p work
agvim delete -p work         # forget it and close it (its folders stay)
agvim list                   # projects, folders, which are running

# Tabs
agvim tab                    # a new shell tab
agvim tab make -p work       # a new tab running a command
agvim agent claude -p work   # a new tab with a coding agent
agvim agents                 # which agents are ready, and where to get the rest
agvim agents --running       # every running agent: Enter goes there
cat log | agvim send         # into the prompt of the agent you used last, unsent
agvim tabs -p work           # the tabs of a project
agvim name build server      # rename the tab you're in
agvim shell                  # a terminal outside any project

# Agents
agvim worktree fix-login     # a new branch in a folder of its own, with its tabs
agvim worktree list          # this project's worktrees
agvim merge                  # merge the worktree you're in: merge, squash or PR
agvim worktree close fix-login
agvim init                   # an AGENTS.md (and CLAUDE.md, GEMINI.md) for this folder
agvim skills                 # pick skills and slash commands to add to this project
agvim skills add resume-session
agvim skills source add https://github.com/you/your-kit

# The workspace
agvim continue               # what was open last time
agvim refresh                # load changes to AgVim, keeping everything open
agvim save                   # save everything now (it's automatic too)
agvim stop                   # save everything and stop it all
agvim keep-running off       # closing the window stops it all (on by default)
agvim diff [rev]             # every git change here, side by side
agvim ai                     # AI suggestions as you type: choose a source, add a key
agvim ai list                # every source, and which are ready
agvim ai test                # check that it really answers
agvim ai signin              # sign in to Copilot
agvim folder                 # where your projects are saved, in Finder
agvim roots add ~/work       # where the project picker looks
agvim terminal iTerm         # which terminal the icon uses (auto: choose for me)
agvim update                 # the latest version and tools, installed again
agvim autoupdate off         # stop updating to new releases when it opens
agvim uninstall              # remove it all, after asking
agvim version
```

`add` and `new` take `--no-open` to save a project without opening anything.

The project picker also lists folders under `~/Projects`, `~/Developer`, `~/code` and `~/Desktop`. To change that, use `agvim roots`.

## Updates

AgVim checks for a new release each time it opens, and updates itself before it starts. It waits a few seconds at most, so being offline only means opening the version you have. It follows releases, not the latest commits, and leaves a clone with your own changes alone. `agvim update` does the same on demand and also updates your tools. `agvim autoupdate off` turns the automatic check off.

## Uninstall

Run `agvim uninstall`. It lists what it will remove and asks first: its links, the app and Desktop icon, Finder's menu, saved projects, Neovim's plugins and data, and running sessions. Anything the install moved aside comes back. Your project folders are never touched.

Homebrew packages stay, since other things may use them. `agvim uninstall --brew` removes those too.

## Change it

The `agvim` tab is this repo. Ask any agent there to change AgVim: `AGENTS.md`, plus skills in `.agents/skills` and the commands `/refresh`, `/test` and `/release`, tell it how. `agvim refresh` shows the result straight away, with everything still open.

```sh
tests/run.sh      # the tests, on separate tmux servers
macos/bundle.sh   # dist/AgVim.app and dist/AgVim.dmg
agvim release 1.1.0   # tests, then a version tag; GitHub builds and publishes it
```

From a clone, `./install.sh` installs that clone. `--no-brew` skips Homebrew and `--no-tools` skips Neovim's tools. Coding agents set up from [AGENTS.md](../AGENTS.md).

| Folder | What it is |
|---|---|
| `bin/agvim` | The one command |
| `lib/` | The scripts behind it; `lib/agents.tsv` is the list of agents |
| `nvim/`, `tmux/` | The Neovim and tmux configs |
| `macos/app/`, `macos/bundle.sh` | The app and how it's built |
| `macos/finder/` | Finder's right-click menu and the icon |
| `tests/` | The tests |
| `saved-projects/` | Your projects (gitignored) |
