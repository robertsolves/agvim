#!/usr/bin/env bash
# Sets up agent-workspace on a Mac: Neovim (code on top, coding agents below),
# tmux, kitty, the `t` / `p` / `gd` commands and Finder's "Open in Neovim".
# Safe to run again: it only changes what isn't set up yet.
#
#   curl -fsSL https://raw.githubusercontent.com/robertsolves/agent-workspace/main/install.sh | bash
#   ./install.sh [--no-brew] [--no-tools]
#
#   --no-brew   skip Homebrew packages (install them yourself, see Brewfile)
#   --no-tools  skip the headless Neovim plugin, parser and language server install
#
# Anything it would replace (~/.config/nvim, ~/.tmux.conf, a script of the same
# name in ~/.local/bin) is moved aside to <name>.bak-<date>, never deleted.
# Run from a curl pipe, it clones the repo to $AGENT_WORKSPACE_DIR
# (default ~/.agent-workspace) first. Your config then links into that folder,
# so `git pull` there updates everything.

set -euo pipefail

REPO_URL=https://github.com/robertsolves/agent-workspace.git
STAMP=$(date +%Y-%m-%d-%H%M%S)
BREW=1
TOOLS=1
for arg in "$@"; do
  case "$arg" in
    --no-brew) BREW=0 ;;
    --no-tools) TOOLS=0 ;;
    -h | --help)
      sed -n '2,17p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "install.sh: unknown option $arg" >&2
      exit 1
      ;;
  esac
done

step() { printf '\n\033[1m==> %s\033[0m\n' "$*"; }
note() { printf '    %s\n' "$*"; }
warn() { printf '\033[33m    ! %s\033[0m\n' "$*"; }

[ "$(uname)" = Darwin ] || {
  echo "install.sh: macOS only (kitty, Finder Quick Action, Xcode tools)." >&2
  exit 1
}

# From a curl pipe there's no checkout around this script: clone one and rerun it.
here=""
if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "${BASH_SOURCE[0]}" ]; then
  here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi
if [ -z "$here" ] || [ ! -f "$here/nvim/init.lua" ]; then
  dir="${AGENT_WORKSPACE_DIR:-$HOME/.agent-workspace}"
  if [ -d "$dir/.git" ]; then
    git -C "$dir" pull --ff-only
  else
    git clone "$REPO_URL" "$dir"
  fi
  exec bash "$dir/install.sh" "$@"
fi
REPO="$here"

# Links $2 to $1. Whatever was at $2 before is moved aside, not deleted.
link() {
  local src="$1" dst="$2"
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    note "ok      $dst"
    return
  fi
  mkdir -p "$(dirname "$dst")"
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    mv "$dst" "$dst.bak-$STAMP"
    note "backup  $dst -> $dst.bak-$STAMP"
  fi
  ln -s "$src" "$dst"
  note "linked  $dst -> $src"
}

step "Homebrew packages"
if [ "$BREW" = 1 ]; then
  command -v brew >/dev/null || {
    echo "Install Homebrew first: https://brew.sh (or rerun with --no-brew)" >&2
    exit 1
  }
  brew bundle --no-upgrade --file="$REPO/Brewfile"
  # Casks only when missing: a kitty or font installed another way makes brew fail.
  [ -d /Applications/kitty.app ] || brew install --cask kitty
  ls ~/Library/Fonts/JetBrainsMonoNerdFont* /Library/Fonts/JetBrainsMonoNerdFont* >/dev/null 2>&1 ||
    brew install --cask font-jetbrains-mono-nerd-font
else
  note "skipped (--no-brew)"
fi

step "Neovim config"
link "$REPO/nvim" "$HOME/.config/nvim"

step "tmux"
link "$REPO/tmux/tmux.conf" "$HOME/.tmux.conf"
if [ ! -d ~/.tmux/plugins/tpm ]; then
  git clone --depth 1 https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi
~/.tmux/plugins/tpm/bin/install_plugins >/dev/null && note "tmux plugins installed"

step "kitty"
link "$REPO/kitty/agent-workspace.conf" "$HOME/.config/kitty/agent-workspace.conf"
link "$REPO/kitty/launch-actions.conf" "$HOME/.config/kitty/launch-actions.conf" # folders dropped on the Dock icon
link "$REPO/kitty/startup-session.conf" "$HOME/.config/kitty/startup-session.conf" # a tab per project on start
kitty_conf=~/.config/kitty/kitty.conf
touch "$kitty_conf"
if ! grep -qx 'include agent-workspace.conf' "$kitty_conf"; then
  printf '\n# agent-workspace (Option as Alt, project tabs, Cmd-T into tmux)\ninclude agent-workspace.conf\n' >>"$kitty_conf"
  note "added include agent-workspace.conf to $kitty_conf"
fi
grep -q '^font_family' "$kitty_conf" ||
  note "Tip: add 'font_family JetBrainsMono Nerd Font' to $kitty_conf for file icons."

step "Commands: open-project, t, p, gd, tab"
for script in "$REPO"/bin/*; do
  link "$script" "$HOME/.local/bin/$(basename "$script")"
done
case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) warn "\$HOME/.local/bin is not on your PATH. Add this to ~/.zshrc: export PATH=\"\$HOME/.local/bin:\$PATH\"" ;;
esac

step "Finder: right-click a folder > Quick Actions > Open in Neovim"
# Copied, not linked: macOS doesn't always pick up a linked workflow.
services=~/Library/Services
mkdir -p "$services"
rm -rf "$services/Open in Neovim.workflow"
cp -R "$REPO/macos/Open in Neovim.workflow" "$services/"
/System/Library/CoreServices/pbs -update
note "installed. If it doesn't show: System Settings > Keyboard > Keyboard Shortcuts > Services > Files and Folders > Open in Neovim."

step "Neovim plugins, treesitter parsers and language servers"
if [ "$TOOLS" = 1 ]; then
  # Mason builds Python tools with the first python3 on PATH. Homebrew's Python 3.15
  # on macOS 26 makes venvs without pip (platform.mac_ver() is empty), so put an
  # older working Python first just for this.
  shim="$(mktemp -d)"
  if ! python3 -c 'import platform, sys; sys.exit(0 if platform.mac_ver()[0] else 1)' 2>/dev/null; then
    for v in 3.14 3.13 3.12; do
      if command -v "python$v" >/dev/null; then
        ln -s "$(command -v "python$v")" "$shim/python3"
        note "using python$v for Mason (python3 can't make venvs on this Mac)"
        break
      fi
    done
  fi
  export PATH="$shim:$PATH"
  nvim --headless "+Lazy! restore" +qa # plugin versions from lazy-lock.json
  nvim --headless -c 'lua require("nvim-treesitter").install(require "configs.treesitter_parsers"):wait(1800000)' +qa
  nvim --headless +MasonToolsInstallSync +qa
  rm -rf "$shim"
  note "done"
else
  note "skipped (--no-tools). They install on Neovim's first start instead."
fi

step "Checks"
for tool in nvim tmux kitty fzf fd rg lazygit rsvg-convert magick; do
  if command -v "$tool" >/dev/null || { [ "$tool" = kitty ] && [ -d /Applications/kitty.app ]; }; then
    note "ok      $tool"
  else
    warn "missing $tool"
  fi
done
missing=""
for tool in flutter fvm cargo rustup python3 node swift terraform xcode-build-server; do
  command -v "$tool" >/dev/null || missing="$missing $tool"
done
[ -z "$missing" ] || note "Not installed (only needed for those languages):$missing"

cat <<'EOF'

Done. Open a project:
  - Finder: right-click a folder > Quick Actions > Open in Neovim
  - Terminal: t (this folder), p (pick a project), gd (git changes of this repo)
Inside Neovim: Space tc starts Claude in a new tab, Alt-g shows git changes.
Keys: nvim/README.md
EOF
