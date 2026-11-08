#!/bin/zsh
repo="${0:A:h:h}"
base=$(mktemp -d /tmp/awf.XXXX); base=${base:A}
export HOME=$base/h TMUX_TMPDIR=$base/t SHELL=/bin/zsh; mkdir -p $HOME/.local/bin $TMUX_TMPDIR; unset TMUX; touch ~/.zshrc
export AGVIM_REAL_TMUX="$(command -v tmux)"; mkdir -p $HOME/stubs; cp "${0:A:h:h}/tests/tmux-guard" $HOME/stubs/tmux; export PATH="$HOME/stubs:$PATH" # only this test's own servers, also if its folder goes
ln -s $repo/bin/agvim ~/.local/bin/agvim; ln -s $repo/tmux/tmux.conf ~/.tmux.conf
print 'set -g default-terminal xterm-256color' > ~/outer.conf
tmux -f ~/.tmux.conf new-session -d -s P -n nvim -x 80 -y 20 -c $HOME 'sleep 300'
for i in {2..14}; do tmux new-window -d -t '=P:' -n "tab-$i-long-name" 'sleep 300'; done
o() { tmux -L outer "$@"; }
o -f ~/outer.conf new-session -d -s o -x 80 -y 20 "env -u TMUX tmux attach -t '=P'"; o set -g status off; sleep 1
row() { o capture-pane -p -t o | sed -n 20p; }
cur() { tmux display -p -t '=P:' '#{window_index} #{window_name} mode=#{pane_in_mode}'; }
click() { o send-keys -t o -l $'\e[<'"0;$1;20M"; o send-keys -t o -l $'\e[<'"0;$1;20m"; sleep 0.6; }
row; cur
echo "click >"; click 70; cur; for n in {1..6}; do click 70; done; row; cur
echo "click <"; click 2; cur
n=$(tmux list-windows -t '=P' | wc -l); echo "click + Shell (windows $n)"; click 75; echo "windows $(tmux list-windows -t '=P' | wc -l)"; cur; row
for i in {15..3}; do tmux kill-window -t "=P:$i" 2>/dev/null; done; sleep .4; r=$(row); print -r -- "few: ${r%% #}"; t=$(print -r -- "$r" | sed -E 's/ +$//'); n=$(tmux list-windows -t '=P' | wc -l); click $(( ${#t} - 2 )); echo "+ Shell with few tabs: $n -> $(tmux list-windows -t '=P' | wc -l)"; cur
o kill-server; tmux kill-server
print $base
