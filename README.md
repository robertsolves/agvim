# AgVim

<img src="docs/icon.svg" width="96" alt="AgVim logo">

A Neovim workspace for Mac that makes agentic coding easy. Big IDEs were built for people typing every line. Now that agents can do so much of that, what's left is reading code, reviewing changes and keeping your agents organised, and that only takes something simple.

Each project gets a tab, with Neovim, lazygit, shells and agents such as Claude, Codex, Copilot, Gemini, DeepSeek and OpenCode side by side. Close a project and it stops using memory. Open it again and your tabs come back. As you type, AI suggestions appear from free Copilot or from your own Claude, OpenAI, Gemini, DeepSeek or other API key.

**Website:** https://robertsolves.github.io/agvim/

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/robertsolves/agvim/main/install.sh | bash
```

Or download [`AgVim.dmg`](https://github.com/robertsolves/agvim/releases/latest/download/AgVim.dmg), drag it to Applications and open it. macOS may ask you to allow it in System Settings → Privacy & Security → **Open Anyway**.

Either way it sets up what's missing once (Homebrew, kitty, git, Neovim, tmux, lazygit and the other basics), then opens in kitty. Tools you already have are kept and updated to their latest versions. Only the languages you code in are yours to install.

## Use

Click the AgVim icon, or type `agvim` in any terminal. It asks what you want to do; `agvim help` lists every command.

The [guide](docs/GUIDE.md) covers projects, tabs, agents, keys and commands. To remove it all: `agvim uninstall`.

## Contribute

See [CONTRIBUTING.md](CONTRIBUTING.md). AgVim opens itself as its first tab, so you can change it from inside it.

## License

[MIT](LICENSE). AgVim builds on many open source projects, [listed on the website](https://robertsolves.github.io/agvim/). The Neovim config starts from NvChad's starter ([its license](nvim/LICENSE)). The icon uses the [Neovim logo](https://neovim.io) by Jason Long ([CC BY 3.0](https://creativecommons.org/licenses/by/3.0/)), recoloured white on black. AgVim isn't affiliated with Neovim.
