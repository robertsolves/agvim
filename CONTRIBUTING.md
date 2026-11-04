# Contributing to AgentNV

Issues and pull requests are welcome. Please keep changes small and AgentNV simple: its point is to stay out of the way.

## Set up

```sh
git clone https://github.com/robertsolves/agentnv.git
cd agentnv
./install.sh
agentnv
```

The `agentnv` tab is your clone, so you can change AgentNV from inside it, with any coding agent. They'll find their instructions in [AGENTS.md](AGENTS.md), and the skills in `.agents/skills`.

## Make a change

1. Change the files in the repo. `~/.config/nvim` and `~/.tmux.conf` are links into it.
2. Run `tests/run.sh`. It uses separate tmux servers, so your running workspace is safe. Add a test when you add a behaviour.
3. Run `agentnv refresh` to see the change with everything still open.
4. Open a pull request saying what changed and why.

## Keep it working for everyone

- It must work on anyone's Mac and in any terminal, with no paths or settings from one machine.
- Every feature is a subcommand of `bin/agentnv`, listed in its help and in [the guide](docs/GUIDE.md).
- Anything `install.sh` adds, `uninstall.sh` must remove.
- Run `shellcheck` on `install.sh`, `uninstall.sh` and `macos/*.sh`.

By contributing, you agree that your work is released under the [MIT License](LICENSE).
