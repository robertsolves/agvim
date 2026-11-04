# AgentNV guide

## Open it

Click the AgentNV icon on your Desktop. It opens AgentNV in kitty, set up with its font, colours and keys for those windows only; your own kitty settings stay as they are. To use another terminal: `agentnv terminal iTerm`.

Or type `agentnv` in any terminal. It asks what you want to do.

## How it works

**Projects** are the tabs along the top. A project is a name and one or more folders. Use `+ Project` to open one, make one from any folder, or add a folder to the one you're in. `+ Shell` opens a terminal that isn't part of any project. The `agentnv` tab is always first, so you can update AgentNV from inside it.

**Tabs** inside a project run along the bottom, each full screen: Neovim, lazygit, a shell, and as many more shells and agents as you want. What you closed stays closed, including a project's other folders, which also leave the project. Only lazygit always comes back when you open a project, along with the `agentnv` tab. `+ Shell` adds a shell.

**The look**: Tokyo Night, dark, in Neovim, the tab bars and shells, with highlighting for Dart and Flutter, Rust, Python, TypeScript, Bash, JSON, Swift, Lua, YAML, TOML, Markdown and more. In Neovim, `Space th` picks another theme.

**Agents**: AgentNV works with Claude, Codex, Copilot, Gemini, DeepSeek, OpenCode, Kilo, Freebuff, Cursor, Aider, Amp and Qwen. Install the ones you use; `agentnv agents` shows which are ready and where to get the rest. In Neovim, `Space t` then a key starts one: `c` Claude, `x` Codex, `p` Copilot, `g` Gemini, `d` DeepSeek, `o` OpenCode, `k` Kilo, `f` Freebuff, `u` Cursor, `a` Aider, `m` Amp, `q` Qwen. Claude starts connected to Neovim, so it sees your selection and shows its edits as diffs. DeepSeek uses [DeepSeek TUI](https://github.com/Hmbown/DeepSeek-TUI), a third-party tool.

**AI autocomplete**: suggestions appear as you type. Tab or Alt-l accepts (once you've moved through the completion menu, Tab moves through that instead), Alt-n and Alt-p ask for another, and Alt-e dismisses. It uses GitHub Copilot's free tier by default, which needs a free GitHub sign-in: choose it in the menu to sign in, or to sign in again when it expires. To add your own key, or use something free, choose **AI autocomplete** in `agentnv`'s menu, or run `agentnv ai`. It works with Claude, OpenAI, Gemini, DeepSeek, Mistral, Grok, Groq, OpenRouter, Together, Fireworks, Cerebras, Kimi, Z.ai and Qwen, with [free-llm-chain](https://github.com/robertsolves/free-llm-chain), and with any OpenAI-compatible service through **Custom endpoint**. It checks a new key straight away, and offers the service's own list of models where it has one; `agentnv ai test` checks again later. Keys are stored in `~/.config/agentnv/ai`, readable only by you. A paid key is charged for every suggestion, so check your provider's prices. Codex uses an OpenAI API key; a ChatGPT or Codex subscription login can't be used here.

**Closing frees the memory.** `×` on a project, or closing the terminal window, saves its tabs and stops everything in them. Opening it again brings back the tabs with what shells last printed, and agents that can continue their last conversation do (Amp and Qwen start fresh). A project only starts when you first look at its tab. Everything is also saved every 5 minutes, in case of a crash.

Other programs, such as a dev server, are stopped and come back as a shell, so start them again. Saved shell output can include anything you printed. It stays on your Mac in `saved-projects/.tabs`, readable only by you.

**Finder**: right-click a folder for **New AgentNV Project**, **Add to AgentNV Project** and **Copy Directory**, which copies its path. If they're missing, turn on agentnv Finder in System Settings → General → Login Items & Extensions → Finder.

## Keys

| Key | What it does |
|---|---|
| Alt-1..9, `Alt-.`, `Alt-,` | go to a tab, next, previous |
| Alt-t | new shell tab |
| Alt-Shift-[ / ] | previous / next project |
| Alt-g | every git change, side by side; again to go back |
| `Space` then wait | every Neovim key |

When a bar has more tabs than fit, it scrolls to keep the current one in view: click `<` or `>`, or use the mouse wheel on it. Rename a tab with `agentnv name <text>` in it, or right-click it. A name you give stays, even when an agent runs there.

More: [nvim/README.md](../nvim/README.md), and the top of [tmux/tmux.conf](../tmux/tmux.conf).

In AgentNV's kitty windows, the **AgentNV** menu in the Mac's menu bar has the main actions, Cmd-T opens a shell tab and Cmd-Shift-[ / ] switch projects. Alt keys need the terminal to send Option as Alt, which those windows do. If you type `agentnv` in another terminal, turn it on yourself: in iTerm2 under Profiles → Keys → Left Option key → Esc+, in Terminal under Settings → Profiles → Keyboard → Use Option as Meta key.

## Commands

Type `agentnv` alone and it asks what you want to do. Everything also works directly. A folder defaults to where you are, and a project to the one you're in; `-p` picks another.

```sh
# Projects
agentnv add .                  # this folder into the project you're in, or a new one
agentnv add . -p work          # this folder into "work", made if needed
agentnv new ~/code/app -n app  # a folder as a new project
agentnv open ~/code/app        # a folder as a project
agentnv open -p work           # a project by name
agentnv open                   # pick one
agentnv close -p work          # save it and stop its tabs
agentnv remove . -p work       # take a folder out
agentnv rename new-name -p work
agentnv delete -p work         # forget it and close it (its folders stay)
agentnv list                   # projects, folders, which are running

# Tabs
agentnv tab                    # a new shell tab
agentnv tab make -p work       # a new tab running a command
agentnv agent claude -p work   # a new tab with a coding agent
agentnv agents                 # which agents are ready, and where to get the rest
agentnv tabs -p work           # the tabs of a project
agentnv name build server      # rename the tab you're in
agentnv shell                  # a terminal outside any project

# The workspace
agentnv continue               # what was open last time
agentnv refresh                # load changes to AgentNV, keeping everything open
agentnv save                   # save everything now (it's automatic too)
agentnv stop                   # save everything and stop it all
agentnv diff [rev]             # every git change here, side by side
agentnv ai                     # AI suggestions as you type: choose a source, add a key
agentnv ai list                # every source, and which are ready
agentnv ai test                # check that it really answers
agentnv ai signin              # sign in to Copilot
agentnv folder                 # where your projects are saved, in Finder
agentnv roots add ~/work       # where the project picker looks
agentnv terminal iTerm         # which terminal the icon uses (auto: choose for me)
agentnv update                 # the latest version, installed again
agentnv uninstall              # remove it all, after asking
agentnv version
```

`add` and `new` take `--no-open` to save a project without opening anything.

The project picker also lists folders under `~/Projects`, `~/Developer`, `~/code` and `~/Desktop`. To change that, use `agentnv roots`.

## Uninstall

Run `agentnv uninstall`. It lists what it will remove and asks first: its links, the app and Desktop icon, Finder's menu, saved projects, Neovim's plugins and data, and running sessions. Anything the install moved aside comes back. Your project folders are never touched.

Homebrew packages stay, since other things may use them. `agentnv uninstall --brew` removes those too.

## Change it

The `agentnv` tab is this repo. Ask any agent there to change AgentNV: `AGENTS.md`, plus skills in `.agents/skills` and the commands `/refresh`, `/test` and `/release`, tell it how. `agentnv refresh` shows the result straight away, with everything still open.

```sh
tests/run.sh      # the tests, on separate tmux servers
macos/bundle.sh   # dist/AgentNV.app and dist/AgentNV.dmg
```

From a clone, `./install.sh` installs that clone. `--no-brew` skips Homebrew and `--no-tools` skips Neovim's tools. Coding agents set up from [AGENTS.md](../AGENTS.md).

| Folder | What it is |
|---|---|
| `bin/agentnv` | The one command |
| `lib/` | The scripts behind it; `lib/agents.tsv` is the list of agents |
| `nvim/`, `tmux/` | The Neovim and tmux configs |
| `macos/app/`, `macos/bundle.sh` | The app and how it's built |
| `macos/finder/` | Finder's right-click menu and the icon |
| `tests/` | The tests |
| `saved-projects/` | Your projects (gitignored) |
