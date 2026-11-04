#!/usr/bin/env bash
# Removes everything install.sh set up, and what the workspace saved since. It
# lists what will go and asks first. Your project folders are never touched.
#
#   ./uninstall.sh [--yes] [--delete-repo] [--brew]
#
#   --yes          don't ask (the clone and Homebrew packages stay unless named below)
#   --delete-repo  also delete this clone
#   --brew         also uninstall the Brewfile's packages and the font. Other
#                  things on your Mac may use them, so it's your call.
#
# Removes:
#   - the links in ~/.config/nvim, ~/.tmux.conf and ~/.local/bin (only ones that lead
#     to this setup), its PATH line in ~/.zshrc, and what earlier versions added to
#     kitty's config
#   - Finder's right-click menu, the AgentNV app and its Desktop icon
#   - saved projects, ~/.config/agentnv, and the tmux plugins and saved
#     sessions of earlier versions
#   - Neovim's plugins, language servers, cache and state (~/.local/share/nvim,
#     ~/.local/state/nvim, ~/.cache/nvim)
#   - the tmux servers, last, closing every session and agent in them
# Whatever install.sh moved aside (<name>.bak-<date>) comes back: the oldest real
# file or folder returns to its place, and any newer ones stay where they are.

set -uo pipefail

YES=0
DELETE_REPO=0
BREW=0
for arg in "$@"; do
  case "$arg" in
    --yes) YES=1 ;;
    --delete-repo) DELETE_REPO=1 ;;
    --brew) BREW=1 ;;
    -h | --help)
      sed -n '2,24p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "uninstall.sh: unknown option $arg" >&2
      exit 1
      ;;
  esac
done

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ ! -f "$REPO/install.sh" ] || [ -z "${HOME:-}" ] || [ "$REPO" = "$HOME" ]; then
  echo "uninstall.sh: run it from the agentnv clone." >&2
  exit 1
fi

note() { printf '    %s\n' "$*"; }
step() { printf '\n\033[1m==> %s\033[0m\n' "$*"; }

# Yes when link $1 leads to this clone's $2, or to that path in a clone that moved
# (nothing is there any more).
is_ours() {
  [ -L "$1" ] || return 1
  local target
  target="$(readlink "$1")"
  [ "$target" = "$REPO/$2" ] && return 0
  case "$target" in
    */"$2") [ ! -e "$1" ] ;;
    *) return 1 ;;
  esac
}

# Removes link $2 to $1 (a path in the repo) and restores what it replaced.
unlink_ours() {
  local rel="$1" dst="$2" backup restored=0
  if is_ours "$dst" "$rel"; then
    rm "$dst"
    note "removed  $dst"
  elif [ -e "$dst" ] || [ -L "$dst" ]; then
    note "left     $dst (not this setup's)"
    restored=1
  fi
  shopt -s nullglob
  for backup in "$dst".bak-*; do
    if is_ours "$backup" "$rel"; then
      rm "$backup"
      note "removed  $backup"
    elif [ -L "$backup" ] && [ ! -e "$backup" ]; then
      rm "$backup"
      note "removed  $backup (a dead link)"
    elif [ "$restored" = 0 ]; then
      mv "$backup" "$dst"
      note "restored $dst from ${backup##*/}"
      restored=1
    else
      note "left     $backup"
    fi
  done
  shopt -u nullglob
}

brew_formulae() { sed -nE 's/^brew "([^"]+)".*/\1/p' "$REPO/Brewfile"; }

dirty=""
if [ -n "$(git -C "$REPO" status --porcelain 2>/dev/null)" ]; then
  dirty=" (it has uncommitted changes)"
fi

if [ "$YES" = 0 ]; then
  if [ ! -t 0 ]; then
    echo "uninstall.sh: nothing to ask on: rerun with --yes to go ahead." >&2
    exit 1
  fi
  sed -n '13,24p' "$0" | sed 's/^# \{0,1\}//'
  echo
  [ "$BREW" = 0 ] || echo "Also: uninstall $(brew_formulae | tr '\n' ' ')and the font."
  [ "$DELETE_REPO" = 0 ] || echo "Also: delete $REPO$dirty."
  [ -z "${TMUX:-}" ] || echo "You're inside tmux: this terminal closes at the very end."
  read -r -p "Remove all of this? (y/N) " answer
  case "$answer" in
    y | Y | yes) ;;
    *)
      echo "Nothing changed."
      exit 0
      ;;
  esac
  if [ "$DELETE_REPO" = 0 ]; then
    read -r -p "Delete this clone too, $REPO$dirty? (y/N) " answer
    case "$answer" in y | Y | yes) DELETE_REPO=1 ;; esac
  fi
fi

step "Links"
unlink_ours nvim "$HOME/.config/nvim"
unlink_ours tmux/tmux.conf "$HOME/.tmux.conf"
for conf in agent-workspace launch-actions startup-session; do
  unlink_ours "kitty/$conf.conf" "$HOME/.config/kitty/$conf.conf"
done
for name in agentnv t p gd open-project project projects tab workspace; do # the rest: earlier versions
  unlink_ours "bin/$name" "$HOME/.local/bin/$name"
done

step "Shell setup"
if [ -f "$HOME/.zshrc" ] && grep -q '# agentnv$' "$HOME/.zshrc"; then
  sed -i '' '/# agentnv$/d' "$HOME/.zshrc"
  note "removed the PATH line from ~/.zshrc"
else
  note "nothing to remove"
fi

step "kitty.conf"
kitty_conf="$HOME/.config/kitty/kitty.conf"
if [ -f "$kitty_conf" ] && grep -qx 'include agent-workspace.conf' "$kitty_conf"; then
  sed -i '' -e '/^# agent-workspace (/d' -e '/^include agent-workspace\.conf$/d' "$kitty_conf"
  note "removed the include. Restart kitty for it to take effect."
else
  note "nothing to remove"
fi

step "Finder's right-click menu"
extension_id=io.github.robertsolves.agentnv.finder.extension
if [ -d "$HOME/Applications/agentnv Finder.app" ]; then
  pluginkit -e ignore -i "$extension_id" 2>/dev/null
  pluginkit -r "$HOME/Applications/agentnv Finder.app/Contents/PlugIns/agentnv-extension.appex" 2>/dev/null
  pkill -f agentnv-extension
fi
rm -rf "$HOME/Applications/agentnv Finder.app" "$HOME/Library/Application Scripts/$extension_id"
rm -rf "$HOME/Library/Containers/$extension_id" 2>/dev/null # macOS may keep this empty folder
for action in "New Project" "Add to Project" "Open in Neovim"; do # earlier versions
  rm -rf "$HOME/Library/Services/$action.workflow"
done
/System/Library/CoreServices/pbs -update 2>/dev/null
note "removed"

step "The AgentNV app and its Desktop icon"
[ ! -L "$HOME/Desktop/AgentNV.app" ] || rm "$HOME/Desktop/AgentNV.app"
rm -rf "$HOME/Applications/AgentNV.app"
if [ "$(defaults read /Applications/AgentNV.app/Contents/Info CFBundleIdentifier 2>/dev/null)" = io.github.robertsolves.agentnv ]; then
  rm -rf /Applications/AgentNV.app
fi
note "removed"

step "Saved projects, plugins and sessions"
rm -rf "$REPO/saved-projects" "$HOME/.config/agent-workspace"
rm -rf "$HOME/.tmux/plugins/tpm" "$HOME/.tmux/plugins/tmux-resurrect" "$HOME/.tmux/plugins/tmux-continuum"
rmdir "$HOME/.tmux/plugins" "$HOME/.tmux" 2>/dev/null
rm -rf "$HOME/.local/share/tmux/resurrect"
rmdir "$HOME/.local/share/tmux" 2>/dev/null
note "removed"

step "Neovim's plugins, language servers, cache and state"
rm -rf "$HOME/.local/share/nvim" "$HOME/.local/state/nvim" "$HOME/.cache/nvim"
note "removed"

if [ "$BREW" = 1 ]; then
  step "Homebrew packages"
  for formula in $(brew_formulae); do
    if brew uninstall "$formula" >/dev/null 2>&1; then
      note "uninstalled $formula"
    else
      note "left $formula (not installed, or something needs it)"
    fi
  done
  if [ -f "$HOME/.config/agentnv/installed-kitty" ]; then
    brew uninstall --cask kitty >/dev/null 2>&1 && note "uninstalled kitty"
  fi
  if brew uninstall --cask font-jetbrains-mono-nerd-font >/dev/null 2>&1; then
    note "uninstalled font-jetbrains-mono-nerd-font"
  else
    note "left font-jetbrains-mono-nerd-font (not installed with Homebrew)"
  fi
else
  printf '\nHomebrew packages stay: other things may use them. To remove them too: brew uninstall %s\n' "$(brew_formulae | tr '\n' ' ')"
fi

rm -rf "$HOME/.config/agentnv"

if [ "$DELETE_REPO" = 1 ]; then
  step "This clone"
  rm -rf "$REPO"
  note "deleted $REPO"
else
  printf '\nThis clone stays at %s. To remove it: rm -rf "%s"\n' "$REPO" "$REPO"
fi

printf '\nDone. Stopping tmux last, so this terminal closes now if it runs inside it.\n'
trap '' HUP
command -v tmux >/dev/null || exit 0
env -u TMUX tmux -L projects kill-server 2>/dev/null
env -u TMUX tmux kill-server 2>/dev/null
exit 0
