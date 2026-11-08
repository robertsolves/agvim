#!/bin/zsh
src="${0:A:h:h}"
base=$(mktemp -d /tmp/awf.XXXX); base=${base:A}
export HOME=$base/home TMUX_TMPDIR=$base/t SHELL=/bin/zsh; mkdir -p $HOME/stubs $HOME/.local/bin $TMUX_TMPDIR ~/code/app; unset TMUX; touch ~/.zshrc
export AGVIM_REAL_TMUX="$(command -v tmux)"; mkdir -p $HOME/stubs; cp "$src/tests/tmux-guard" $HOME/stubs/tmux; export PATH="$HOME/stubs:$PATH" # only this test's own servers, also if its folder goes
repo=$HOME/clone; mkdir -p $repo; (cd $src && git ls-files -co --exclude-standard -z | while IFS= read -r -d '' f; do [ -e "$f" ] && { mkdir -p "$repo/${f:h}"; cp -pR "$f" "$repo/$f"; }; done); git -C $repo init -q
ln -s $repo/bin/agvim ~/.local/bin/agvim; ln -s $repo/tmux/tmux.conf ~/.tmux.conf
for p in nvim lazygit; do print -l '#!/bin/zsh' '[[ "$*" == *--headless* ]] && exit 0' "exec -a $p sleep 1000" > ~/stubs/$p; chmod +x ~/stubs/$p; done
export PATH="$HOME/stubs:$HOME/.local/bin:$PATH"
print 'set -g default-terminal xterm-256color' > ~/outer.conf
o() { tmux -L outer "$@"; }; b() { tmux -L projects "$@"; }
cd ~/code/app; agvim new . -n App --no-open
o -f ~/outer.conf new-session -d -s o -x 110 -y 30 "agvim open -p App; sleep 100"; o set -g status off; sleep 3
tmux select-window -t '=App:=shell 1'; sleep .5
row() { o capture-pane -p -t o | sed -E 's/ +$//' | awk 'NF' | tail -1; }
row
o send-keys -t o -l 'agvim name build server'; o send-keys -t o Enter; sleep 1.5; row
o send-keys -t o -l "printf '\\033]2;Agent Title\\033\\\\'; sleep 4"; o send-keys -t o Enter; sleep 1.5; echo "title now: $(tmux display -p -t '=App:' '#{pane_title}')"; tmux refresh-client -S 2>/dev/null; sleep .5; echo "while a program sets a title:"; row
sleep 4; agvim close -p App; sleep 1; cut -f2,9 $repo/saved-projects/.tabs/App/tabs | tr '\t' '=' | tr '\n' ' '; echo
agvim open -p App </dev/null >/dev/null 2>&1 & sleep 3; b select-window -t '=projects:=App'; sleep 1; tmux list-windows -t '=App' -F '  #W named=#{@named}'; row; echo "mode=$(tmux display -p -t '=App:' '#{pane_in_mode}')"
TMUX= TMUX_PANE= agvim name x; echo rc=$?
o kill-server; b kill-server; tmux kill-server
