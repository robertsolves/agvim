#!/bin/zsh
src="${0:A:h:h}"
base=$(mktemp -d /tmp/awf.XXXX); base=${base:A}
export HOME=$base/home TMUX_TMPDIR=$base/t SHELL=/bin/zsh; mkdir -p $HOME/stubs $HOME/.local/bin $TMUX_TMPDIR ~/code/a ~/code/b ~/code/c ~/code/d; unset TMUX; touch ~/.zshrc
repo=$HOME/clone; mkdir -p $repo; (cd $src && git ls-files -co --exclude-standard -z | while IFS= read -r -d '' f; do [ -e "$f" ] && { mkdir -p "$repo/${f:h}"; cp -pR "$f" "$repo/$f"; }; done); git -C $repo init -q
ln -s $repo/bin/agvim ~/.local/bin/agvim; ln -s $repo/tmux/tmux.conf ~/.tmux.conf
for p in nvim lazygit; do print -l '#!/bin/zsh' '[[ "$*" == *--headless* ]] && exit 0' "exec -a $p sleep 1000" > ~/stubs/$p; chmod +x ~/stubs/$p; done
export PATH="$HOME/stubs:$HOME/.local/bin:$PATH"
print 'set -g default-terminal xterm-256color' > ~/outer.conf
o() { tmux -L outer "$@"; }; b() { tmux -L projects "$@"; }
win() { tmux list-windows -t '=A' -F '#W' 2>&1 | tr '\n' ',' ; echo; }
list() { agvim list | grep -v '^agvim' | sed "s#$HOME/code/##g"; }
agvim new ~/code/a -n A --no-open; agvim add ~/code/b -p A --no-open
o -f ~/outer.conf new-session -d -s o -x 120 -y 30 "agvim open -p A; sleep 200"; o set -g status off; sleep 3
echo "opened:   $(win)"; list
C=$(tmux list-clients -t '=A' -F '#{client_name}' | head -1); W=$(tmux list-windows -t '=A' -F '#W #{window_id}' | awk '$1=="b"{print $2}')
agvim _tab new "$(tmux display -p -t '=A:' '#{session_id}')"; sleep .4
~/.local/bin/agvim _tab close "$C" "$W"; sleep .4; o capture-pane -p -t o | sed -E 's/ +$//' | awk 'NF' | tail -1 | cut -c1-70; o send-keys -t o y; sleep 1.5
echo "x folder: $(win)"; list; echo "mode=$(tmux display -p -t '=A:' '#{pane_in_mode}')"
tmux kill-window -t '=A:=shell 2'; tmux kill-window -t '=A:=lazygit'; tmux new-window -d -t '=A:' -n "keep me" -c ~/code/a; sleep .3
agvim close -p A; sleep 1; agvim add ~/code/c -p A --no-open; echo "closed, added c:"; list
agvim open -p A </dev/null >/dev/null 2>&1; sleep 1.5; b select-window -t '=projects:=A'; sleep 1.5
echo "reopened: $(win)  (no b, no shell 2; lazygit back; keep me and c there)"; tmux list-windows -t '=A' -F '  #W ftab=#{@folder_tab} folder=#{@folder}' | sed "s#$HOME/code/##"
echo "--- nvim tab closed stays closed"; tmux kill-window -t '=A:=nvim'; agvim close -p A; sleep 1; agvim open -p A </dev/null >/dev/null 2>&1; sleep 1.5; b select-window -t '=projects:=A'; sleep 1.5; echo "$(win)"
echo "--- remove with the tab open"; agvim remove ~/code/c -p A; echo "$(win)"; list
echo "--- restart keeps agvim and only what was open"; pid=$(b list-clients -F '#{client_pid}'); kill -HUP $pid; sleep 3.5; o kill-server 2>/dev/null; sleep .4; tr '\n' ',' < $repo/saved-projects/.open; echo
echo "--- wizard"; o -f ~/outer.conf new-session -d -s o -x 120 -y 30 "agvim; print EXIT=\$?; sleep 60"; o set -g status off; sleep 1.5; o capture-pane -p -t o | sed -E 's/ +$//' | awk 'NF' | cut -c1-60 | head -12
o send-keys -t o -l Rename; sleep .4; o send-keys -t o Enter; sleep .8; o send-keys -t o Enter; sleep .8; o capture-pane -p -t o | sed -E 's/ +$//' | awk 'NF' | tail -2 | cut -c1-60; o send-keys -t o -l B2; o send-keys -t o Enter; sleep 1; list
o capture-pane -p -t o | grep -c 'Rename a project' | xargs echo "back at menu after rename:"; o capture-pane -p -t o | grep -q 'is now B2' && echo "rename message shown"
o send-keys -t o -l Open; sleep .4; o send-keys -t o BSpace BSpace BSpace BSpace; sleep .3; o send-keys -t o -l 'Open project'; sleep .4; o send-keys -t o Enter; sleep .8; o capture-pane -p -t o | grep -c 'project>' | xargs echo "in picker:"; o send-keys -t o Escape; sleep .8; o capture-pane -p -t o | grep -c 'Rename a project' | xargs echo "back at menu after Esc in picker:"
o send-keys -t o Escape; sleep .8; o capture-pane -p -t o | grep -c 'EXIT=0' | xargs echo "Esc at menu leaves, exit 0:"; o kill-server; sleep .3
agvim new ~/code/d --no-open; o -f ~/outer.conf new-session -d -s o -x 120 -y 30 "agvim delete; print EXIT=\$?; sleep 60"; o set -g status off; sleep 1.2; o send-keys -t o -l d; sleep .4; o send-keys -t o Enter; sleep .8; o capture-pane -p -t o | grep -c 'Delete d' | xargs echo "asks:"; o send-keys -t o n; o send-keys -t o Enter; sleep .8; list; o kill-server; sleep .3; agvim delete -p d; list
echo "--- Continue only for what still exists, and Exit"; agvim open -p B2 </dev/null >/dev/null 2>&1; sleep 1.5; agvim save; b kill-server; tmux kill-server; sleep .4; print -l agvim B2 > $repo/saved-projects/.open
wiz() { o -f ~/outer.conf new-session -d -s o -x 120 -y 30 "agvim; print EXIT=\$?; sleep 30"; o set -g status off; sleep 1.2; }
wiz; o capture-pane -p -t o | grep -c 'Continue where you left off (B2)' | xargs echo "continue while it exists:"; o capture-pane -p -t o | grep -c 'Open a shell' | xargs echo "open a shell row:"; o capture-pane -p -t o | sed -E 's/ +$//' | awk 'NF' | tail -1 | cut -c1-20 | xargs echo "last row:"; o send-keys -t o -l Exit; sleep .4; o send-keys -t o Enter; sleep .7; o capture-pane -p -t o | grep -c 'EXIT=0' | xargs echo "exit row leaves:"; o kill-server; sleep .3
agvim delete -p B2; tr '\n' ',' < $repo/saved-projects/.open; echo; wiz; o capture-pane -p -t o | grep -c 'Continue where' | xargs echo "continue once deleted:"; o kill-server; sleep .3; agvim new ~/code/a -n B2 --no-open
echo "--- refresh and popup, running"; o -f ~/outer.conf new-session -d -s o -x 120 -y 30 "agvim open -p B2; sleep 200"; o set -g status off; sleep 3; tmux set -g @probe 1; tmux set -gu window-style; agvim refresh; echo "window-style back: $(tmux show -gv window-style)"; echo "panes alive: $(tmux list-panes -s -t '=B2' | wc -l | tr -d ' ') mode=$(tmux display -p -t '=B2:' '#{pane_in_mode}')"
~/.local/bin/agvim _projects popup >/dev/null 2>&1 &
sleep 1.5; o capture-pane -p -t o | grep -E 'Rename a project|Show what' | cut -c10-50; o send-keys -t o Escape; sleep .6
o kill-server 2>/dev/null; b kill-server 2>/dev/null; tmux kill-server 2>/dev/null
