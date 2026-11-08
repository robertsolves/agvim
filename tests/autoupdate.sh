#!/bin/zsh
# Opening AgVim moves a clean clone to the newest release, and leaves everything else be.
src="${0:A:h:h}"
base=$(mktemp -d /tmp/awf.XXXX); base=${base:A}
export HOME=$base/home TMUX_TMPDIR=$base/t SHELL=/bin/zsh GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
export AGVIM_REAL_TMUX="$(command -v tmux)"; mkdir -p $HOME/stubs; cp "$src/tests/tmux-guard" $HOME/stubs/tmux; export PATH="$HOME/stubs:$PATH" # only this test's own servers, also if its folder goes
mkdir -p $HOME/stubs $HOME/.local/bin $TMUX_TMPDIR; touch ~/.zshrc; unset TMUX
for p in brew nvim open; do print -l '#!/bin/zsh' 'exit 0' > ~/stubs/$p; chmod +x ~/stubs/$p; done
print -l '#!/bin/zsh' 'exit 0' > ~/stubs/tmux-keep
export PATH="$HOME/stubs:$PATH"
[[ "$(command -v brew)" == $HOME/stubs/brew ]] || { echo REAL-BREW; exit 1; }
git init -q --bare $base/remote.git; git -C $base/remote.git symbolic-ref HEAD refs/heads/main
seed=$base/seed; mkdir -p $seed; (cd $src && git ls-files -co --exclude-standard -z | while IFS= read -r -d '' f; do [ -e "$f" ] && { mkdir -p "$seed/${f:h}"; cp -pR "$f" "$seed/$f"; }; done)
git -C $seed init -q -b main; git -C $seed add -A; git -C $seed commit -qm one; git -C $seed tag v1.0.0; git -C $seed remote add origin $base/remote.git; git -C $seed push -q -u origin main --tags
clone() { rm -rf "$1"; git clone -q $base/remote.git "$1"; git -C "$1" checkout -q main; git -C "$1" reset -q --hard v1.0.0; ln -sfn "$1/bin/agvim" ~/.local/bin/agvim; mkdir -p ~/.config/agvim; }
where() { git -C "$1" describe --tags --always; }
# A newer release, and a newer commit that isn't released.
print -r -- '# released later' >> $seed/README.md; git -C $seed commit -qam two; git -C $seed tag v1.1.0; print -r -- '# unreleased' >> $seed/README.md; git -C $seed commit -qam three; git -C $seed push -q origin main --tags
c=$HOME/clone
# The wizard needs a terminal, so `continue` stands in; a bar with no window ends at once.
go() { perl -e 'alarm 25; exec @ARGV' "$1/bin/agvim" continue </dev/null 2>&1 | grep -E 'Updat|updat|Couldn' ; tmux -L projects kill-server 2>/dev/null; tmux kill-server 2>/dev/null; true; }
clone $c; out="$(go $c)"; print -r -- "clean clone moved to: $(where $c)"; print -r -- "$out" | sed 's/^/message: /'; print -r -- "new version runs: $(where $c)"
go $c >/dev/null; print -r -- "already current stays: $(where $c)"
clone $c; print -r -- mine >> $c/README.md; go $c >/dev/null; print -r -- "your changes kept: $(grep -c '^mine$' $c/README.md) at $(where $c)"
clone $c; touch ~/.config/agvim/auto-update-off; go $c >/dev/null; print -r -- "off stays on: $(where $c)"; rm ~/.config/agvim/auto-update-off
clone $c; git -C $c remote set-url origin http://127.0.0.1:9/none.git; s=$SECONDS; go $c >/dev/null; print -r -- "offline still opens: $([ $((SECONDS - s)) -lt 20 ] && print yes || print no) ($((SECONDS - s))s) at $(where $c)"
