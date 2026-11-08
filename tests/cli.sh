#!/bin/zsh
src="${0:A:h:h}"
base=$(mktemp -d /tmp/awf.XXXX); base=${base:A}
export HOME=$base/home TMUX_TMPDIR=$base/t SHELL=/bin/zsh; mkdir -p $HOME/stubs $HOME/.local/bin $TMUX_TMPDIR ~/code/app ~/code/two "$HOME/code/my lib" ~/roots1; unset TMUX; touch ~/.zshrc
export AGVIM_REAL_TMUX="$(command -v tmux)"; mkdir -p $HOME/stubs; cp "$src/tests/tmux-guard" $HOME/stubs/tmux; export PATH="$HOME/stubs:$PATH" # only this test's own servers, also if its folder goes
repo=$HOME/clone; mkdir -p $repo; (cd $src && git ls-files -co --exclude-standard -z | while IFS= read -r -d '' f; do [ -e "$f" ] && { mkdir -p "$repo/${f:h}"; cp -pR "$f" "$repo/$f"; }; done); git -C $repo init -q
ln -s $repo/bin/agvim ~/.local/bin/agvim; ln -s $repo/tmux/tmux.conf ~/.tmux.conf
for p in nvim lazygit claude; do print -l '#!/bin/zsh' '[[ "$*" == *--headless* ]] && exit 0' "exec -a $p sleep 1000" > ~/stubs/$p; chmod +x ~/stubs/$p; done; print -l '#!/bin/zsh' 'print open "$@" >> $HOME/open.log' > ~/stubs/open; chmod +x ~/stubs/open
export PATH="$HOME/stubs:$HOME/.local/bin:$PATH"
a() { print -r -- "\$ agvim $*"; agvim "$@" 2>&1; local rc=$?; [ $rc = 0 ] || print -r -- "  rc=$rc"; }
cd ~/code/app
a add . --no-open; a list
cd ~/code/two; a add . -p app --no-open; a add . -p fresh --no-open; a list
cd "$HOME/code/my lib"; a new . -n "my lib" --no-open; a new . --no-open; a add /nope; a add . -x; a list
a tabs -p app; a rename apps -p app; a list; a remove ~/code/two -p apps; a list
a close; a tabs; a delete -p fresh; a delete -p agvim; a rename x -p agvim; a delete ../..; a open -p nope </dev/null
a roots; a roots add ~/roots1; a roots remove ~/Desktop; a terminal /nope; a terminal Terminal; a terminal auto; a version; a nope; a help | head -3
echo "=== with the bar"; print 'set -g default-terminal xterm-256color' > ~/outer.conf
o() { tmux -L outer "$@"; }; b() { tmux -L projects "$@"; }
o -f ~/outer.conf new-session -d -s o -x 110 -y 30 "cd ~/code/app; agvim open -p apps; sleep 100"; o set -g status off; sleep 3; o capture-pane -p -t o | sed -n 1p | sed -E 's/ +$//'
tmux list-windows -t '=apps' -F '  #{window_name}'; a list; a tabs -p apps
a tab -p apps; a tab claude -p apps; a tabs -p apps
a save; ls -a $repo/saved-projects | tr '\n' ' '; echo
# from a shell inside the project
tmux select-window -t '=apps:=shell 1'; sleep .4; o send-keys -t o -l "cd ~/code/two; agvim add . > ~/in.log 2>&1; agvim tabs >> ~/in.log 2>&1; cd ~/code/app"; o send-keys -t o Enter; sleep 2.5; cat ~/in.log; a list
tmux select-window -t '=apps:=shell 1'; sleep .4; o send-keys -t o -l "agvim rename live > ~/in.log 2>&1"; o send-keys -t o Enter; sleep 1.5; cat ~/in.log; o capture-pane -p -t o | sed -n 1p | sed -E 's/ +$//'; a tabs -p live
a close -p live; sleep 1; a list; b list-windows -F '  #W'; a tabs -p live; a stop; sleep 1; tmux ls 2>&1 | cut -c1-20; b ls 2>&1 | cut -c1-20; cat $repo/saved-projects/.open | tr '\n' ','; echo
tmux -L outer kill-server 2>/dev/null; b kill-server 2>/dev/null; tmux kill-server 2>/dev/null
