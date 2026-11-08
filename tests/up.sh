#!/bin/zsh
src="${0:A:h:h}"
base=$(mktemp -d /tmp/awf.XXXX); base=${base:A}
export HOME=$base/home TMUX_TMPDIR=$base/t; mkdir -p $HOME/stubs $TMUX_TMPDIR; touch ~/.zshrc
export AGVIM_REAL_TMUX="$(command -v tmux)"; mkdir -p $HOME/stubs; cp "$src/tests/tmux-guard" $HOME/stubs/tmux; export PATH="$HOME/stubs:$PATH" # only this test's own servers, also if its folder goes
repo=$HOME/clone; mkdir -p $repo; (cd $src && git ls-files -co --exclude-standard -z | while IFS= read -r -d '' f; do [ -e "$f" ] && { mkdir -p "$repo/${f:h}"; cp -pR "$f" "$repo/$f"; }; done)
print -l '#!/bin/zsh' 'print -r -- "brew $*" >> $HOME/log' 'if [ "$1" = list ]; then [ "$3" = kitty ]; exit $?; fi' 'exit 0' > ~/stubs/brew; chmod +x ~/stubs/brew
print -l '#!/bin/zsh' 'print -r -- "nvim $*" >> $HOME/log' > ~/stubs/nvim; chmod +x ~/stubs/nvim
print -l '#!/bin/zsh' 'print -r -- "open $*" >> $HOME/log' > ~/stubs/open; chmod +x ~/stubs/open
mkdir -p ~/.local/share/nvim/mason/packages/x
export PATH="$HOME/stubs:$PATH"
[[ "$(command -v brew)" == $HOME/stubs/brew ]] || { echo REAL-BREW; exit 1; }
git -C $repo init -q; cd $repo; ./install.sh --no-tools > ~/out 2>&1; echo "install rc=$?"; cut -c1-100 ~/log; grep -E '!' ~/out | cut -c1-90
: > ~/log; ./install.sh --no-brew > ~/out 2>&1; echo "tools rc=$?"; cut -c1-90 ~/log
print "$base"
