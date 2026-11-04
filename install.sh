#!/usr/bin/env bash
# Sets up agentnv on a Mac: projects as tabs in any terminal, each a tmux session
# with Neovim, shells and agents as tabs; the `agentnv` command
# and Finder's "New AgentNV Project" and "Add to AgentNV Project". Run `agentnv` in any
# terminal to use it. uninstall.sh removes it all.
# Safe to run again: it sets up what's missing and updates the tools already there.
#
#   curl -fsSL https://raw.githubusercontent.com/robertsolves/agentnv/main/install.sh | bash
#   ./install.sh [--no-brew] [--no-tools]
#
#   --no-brew   skip Homebrew packages (install them yourself, see Brewfile)
#   --no-tools  skip the headless Neovim plugin and parser install
#
# It installs whatever's missing, Homebrew included (that asks for your password).
# Anything it would replace (~/.config/nvim, ~/.tmux.conf, a command called agentnv
# in ~/.local/bin) is moved aside to <name>.bak-<date>, never deleted.
# Run from a curl pipe, it clones the repo to $AGENTNV_DIR
# (default ~/.agentnv) first. Your config then links into that folder,
# so `git pull` there updates everything.

set -euo pipefail

REPO_URL=https://github.com/robertsolves/agentnv.git
STAMP=$(date +%Y-%m-%d-%H%M%S)
BREW=1
TOOLS=1
for arg in "$@"; do
  case "$arg" in
    --no-brew) BREW=0 ;;
    --no-tools) TOOLS=0 ;;
    -h | --help)
      sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'
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
  echo "install.sh: macOS only (Finder extension, Xcode tools)." >&2
  exit 1
}

# From a curl pipe there's no checkout around this script: clone one and rerun it.
here=""
if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "${BASH_SOURCE[0]}" ]; then
  here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi
if [ -z "$here" ] || [ ! -f "$here/nvim/init.lua" ]; then
  dir="${AGENTNV_DIR:-$HOME/.agentnv}"
  if [ -d "$dir/.git" ]; then
    git -C "$dir" pull --ff-only
  else
    git clone "$REPO_URL" "$dir"
  fi
  exec bash "$dir/install.sh" "$@"
fi
REPO="$here"
"$REPO/lib/banner"
# A first install ends by opening AgentNV. Installing again only updates.
FRESH=0
[ -e "$HOME/.local/bin/agentnv" ] || FRESH=1

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

export PATH="$PATH:/opt/homebrew/bin:/usr/local/bin"

step "Homebrew packages"
if [ "$BREW" = 1 ]; then
  if ! command -v brew >/dev/null; then
    note "Installing Homebrew, which installs the rest. It asks for your password."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" </dev/tty
  fi
  # Installs what's missing; what's there already just gets updated.
  brew bundle --file="$REPO/Brewfile"
  # shellcheck disable=SC2046 # one word per package
  brew upgrade $(sed -nE 's/^brew "([^"]+)".*/\1/p' "$REPO/Brewfile") || warn "couldn't update every Homebrew package. See above."
  # Cask only when missing: a font installed another way makes brew fail.
  ls ~/Library/Fonts/JetBrainsMonoNerdFont* /Library/Fonts/JetBrainsMonoNerdFont* >/dev/null 2>&1 ||
    brew install --cask font-jetbrains-mono-nerd-font
  # AgentNV's windows open in kitty (lib/terminal, macos/kitty.conf).
  if [ ! -d /Applications/kitty.app ] && [ ! -d "$HOME/Applications/kitty.app" ]; then
    brew install --cask kitty
    mkdir -p "$HOME/.config/agentnv"
    touch "$HOME/.config/agentnv/installed-kitty"
  fi
  # Only Homebrew's own copies: one installed another way updates itself.
  for cask in kitty font-jetbrains-mono-nerd-font; do
    if brew list --cask "$cask" >/dev/null 2>&1; then
      brew upgrade --cask "$cask" || warn "couldn't update $cask. See above."
    fi
  done
else
  note "skipped (--no-brew)"
fi

step "Neovim config"
link "$REPO/nvim" "$HOME/.config/nvim"

step "tmux"
link "$REPO/tmux/tmux.conf" "$HOME/.tmux.conf"

# Earlier versions set kitty up to open the workspace. Your terminal is yours now.
for conf in agent-workspace launch-actions startup-session; do
  conf="$HOME/.config/kitty/$conf.conf"
  if [[ "$(readlink "$conf" 2>/dev/null)" == */kitty/*.conf ]]; then
    rm "$conf"
    note "removed $conf"
  fi
done
kitty_conf="$HOME/.config/kitty/kitty.conf"
if [ -f "$kitty_conf" ] && grep -qx 'include agent-workspace.conf' "$kitty_conf"; then
  sed -i '' -e '/^# agent-workspace (/d' -e '/^include agent-workspace\.conf$/d' "$kitty_conf"
  note "removed the agent-workspace include from $kitty_conf"
fi

step "The agentnv command"
# Earlier versions linked each script and kept their settings elsewhere.
for old in t p gd open-project project projects tab workspace; do
  if [[ "$(readlink "$HOME/.local/bin/$old" 2>/dev/null)" == */bin/"$old" ]]; then
    rm "$HOME/.local/bin/$old"
    note "removed ~/.local/bin/$old (now agentnv)"
  fi
done
if [ -d "$HOME/.config/agent-workspace" ] && [ ! -e "$HOME/.config/agentnv" ]; then
  mv "$HOME/.config/agent-workspace" "$HOME/.config/agentnv"
  note "moved ~/.config/agent-workspace to ~/.config/agentnv"
fi
for script in "$REPO"/bin/*; do
  link "$script" "$HOME/.local/bin/$(basename "$script")"
done
case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *)
    # So `agentnv` works in a new terminal. uninstall.sh removes the line.
    if ! grep -qs '# agentnv$' "$HOME/.zshrc"; then
      printf 'export PATH="$HOME/.local/bin:$PATH" # agentnv\n' >>"$HOME/.zshrc"
      note "added ~/.local/bin to your PATH in ~/.zshrc"
    fi
    ;;
esac

step "Finder: New AgentNV Project and Add to AgentNV Project when you right-click a folder"
rm -rf "$HOME/Library/Services/Open in Neovim.workflow" "$HOME/Library/Services/New Project.workflow" "$HOME/Library/Services/Add to Project.workflow" # earlier versions
if "$REPO/macos/finder/build.sh" >/dev/null 2>&1; then
  note "installed. If they don't show: System Settings > General > Login Items & Extensions > Finder, and turn on agentnv Finder."
else
  warn "couldn't build it (Xcode Command Line Tools: xcode-select --install). Everything else works without it. To retry: $REPO/macos/finder/build.sh"
fi

step "The AgentNV app and its icon on your Desktop"
# Downloaded, it's in /Applications already. Otherwise build it from this repo.
app=/Applications/AgentNV.app
if [ ! -d "$app" ]; then
  app="$HOME/Applications/AgentNV.app"
  if "$REPO/macos/bundle.sh" --app-only >/dev/null 2>&1; then
    mkdir -p "$HOME/Applications"
    rm -rf "$app"
    cp -R "$REPO/dist/AgentNV.app" "$app"
    note "built $app"
  else
    warn "couldn't build the app. Everything else works without it."
  fi
fi
# Once, so an icon you've deleted stays deleted.
mkdir -p "$HOME/.config/agentnv"
if [ -d "$app" ] && [ ! -e "$HOME/.config/agentnv/desktop-icon" ]; then
  if ln -sfn "$app" "$HOME/Desktop/AgentNV.app" 2>/dev/null; then
    touch "$HOME/.config/agentnv/desktop-icon"
    note "added AgentNV to your Desktop"
  else
    warn "couldn't add the icon to your Desktop: open AgentNV from $app instead."
  fi
fi

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
  nvim --headless -c 'lua require("nvim-treesitter").update():wait(1800000)' +qa
  # Language servers install by themselves when Neovim first opens, so the setup stays
  # short. Those already here get updated.
  if [ -n "$(ls "$HOME/.local/share/nvim/mason/packages" 2>/dev/null)" ]; then
    nvim --headless +MasonToolsUpdateSync +qa
  fi
  rm -rf "$shim"
  note "done"
else
  note "skipped (--no-tools). They install on Neovim's first start instead."
fi

step "Neovim's colours"
# Neovim reads them from a compiled copy, so a new theme needs it built again.
nvim --headless "+lua require('base46').load_all_highlights()" +qa >/dev/null 2>&1 || note "skipped: they're built on Neovim's first start"

step "Checks"
for tool in nvim tmux kitty fzf fd rg lazygit rsvg-convert magick; do
  if command -v "$tool" >/dev/null || { [ "$tool" = kitty ] && { [ -d /Applications/kitty.app ] || [ -d "$HOME/Applications/kitty.app" ]; }; }; then
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

if [ "$FRESH" = 1 ] && [ -z "${AGENTNV_NO_LAUNCH:-}" ]; then
  "$HOME/.local/bin/agentnv" _projects new-terminal
fi

cat <<'EOF'

Done. In any terminal, run: agentnv
  - It asks what you want. For every command: agentnv help
  - Finder: right-click a folder > New AgentNV Project or Add to AgentNV Project
  - Or click the AgentNV icon on your Desktop
Inside Neovim: Space tc starts Claude in a new tab, Alt-g shows git changes.
Keys: nvim/README.md
EOF
