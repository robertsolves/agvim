# Contributing to AgVim

Issues and pull requests are welcome. Please keep changes small and AgVim simple: its point is to stay out of the way.

## Set up

```sh
git clone https://github.com/robertsolves/agvim.git
cd agvim
./install.sh
agvim
```

The `agvim` tab is your clone, so you can change AgVim from inside it, with any coding agent. They'll find their instructions in [AGENTS.md](AGENTS.md), and the skills in `.agents/skills`.

## Make a change

1. Change the files in the repo. `~/.config/nvim` and `~/.tmux.conf` are links into it.
2. Run `tests/run.sh`. It uses separate tmux servers, so your running workspace is safe. Add a test when you add a behaviour.
3. Run `agvim refresh` to see the change with everything still open.
4. Open a pull request saying what changed and why.

## Keep it working for everyone

- It must work on anyone's Mac and in any terminal, with no paths or settings from one machine.
- Every feature is a subcommand of `bin/agvim`, listed in its help and in [the guide](docs/GUIDE.md).
- Anything `install.sh` adds, `uninstall.sh` must remove.
- Run `shellcheck` on `install.sh`, `uninstall.sh` and `macos/*.sh`.

## Release a new version

Run `agvim release 1.1.0` from a clean, pushed `main`. It runs the tests, asks, and pushes a version tag. GitHub then builds `AgVim.dmg` and publishes the release, and everyone's AgVim updates to it the next time it opens. The website deploys by itself when `docs/` changes on `main`.

By contributing, you agree that your work is released under the [MIT License](LICENSE).
