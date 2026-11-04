#!/bin/zsh
src="${0:A:h:h}"
base=$(mktemp -d /tmp/awf.XXXX); base=${base:A}
export HOME=$base/home TMUX_TMPDIR=$base/t SHELL=/bin/zsh GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
mkdir -p $HOME $TMUX_TMPDIR ~/stubs ~/Work/alpha; unset TMUX; touch ~/.zshrc
export PATH="$HOME/.local/bin:$HOME/stubs:$PATH"
print -l '#!/bin/zsh' 'print open "$@" >> $HOME/open.log' > ~/stubs/open; chmod +x ~/stubs/open
print -l '#!/bin/zsh' '[[ "$*" == *--headless* ]] && exit 0' 'exec -a nvim sleep 1000' > ~/stubs/nvim; chmod +x ~/stubs/nvim
git init -q --bare $base/remote.git
seed=$base/seed; mkdir -p $seed; (cd $src && git ls-files -co --exclude-standard -z | while IFS= read -r -d '' f; do [ -e "$f" ] && { mkdir -p "$seed/${f:h}"; cp -pR "$f" "$seed/$f"; }; done)
git -C $seed init -q -b main; git -C $seed add -A; git -C $seed commit -qm one; git -C $seed remote add origin $base/remote.git; git -C $seed push -q -u origin main
git -C $base/remote.git symbolic-ref HEAD refs/heads/main
git clone -q $base/remote.git ~/clone; (cd ~/clone && ./install.sh --no-brew --no-tools >/dev/null 2>&1); command -v agvim
print 'set -g default-terminal xterm-256color' > ~/outer.conf
o() { tmux -L outer "$@"; }
shot() { echo "----- $1"; o capture-pane -p -t o | sed -E 's/ +$//' | awk 'NF' | cut -c1-100 | head -${2:-9}; }
run() { o -f ~/outer.conf new-session -d -s o -x 100 -y 30 "$1; print EXIT=\$?; sleep 60"; o set -g status off; sleep 1.5; }
key() { o send-keys -t o "$@"; sleep 0.8; }
echo "=== menu, no history"; run agvim; shot menu 7; key Escape; shot "esc" 2; o kill-server; sleep .3
echo "=== folder"; run agvim; o send-keys -t o -l 'projects folder'; sleep .4; key Enter; shot done 3; key Escape; cat ~/open.log; o kill-server; sleep .3
echo "=== uninstall row, answer no"; run agvim; o send-keys -t o -l Uninstall; sleep .4; key Enter; shot prompt 14 | tail -3; key n; key Enter; shot "no" 3 | tail -2; o kill-server; sleep .3; ls -l ~/.local/bin/agvim | cut -c1-10
echo "=== open project -> picker -> new"; run agvim; key Enter; o send-keys -t o Enter; sleep .8; o send-keys -t o -l Work; sleep .4; key Enter; o send-keys -t o -l alpha; sleep .4; key Enter; key Enter; key Enter; sleep 2; shot opened 3
tmux list-sessions -F '  #{session_name}'; pid=$(tmux -L projects list-clients -F '#{client_pid}'); kill -HUP $pid; sleep 3; o kill-server 2>/dev/null; sleep .3; tmux ls 2>&1 | head -1
echo "=== menu with history"; run agvim; shot menu 5; key Enter; sleep 2; shot continued 3; tmux list-sessions -F '  #{session_name}'
echo "=== update good"; git clone -q $base/remote.git $base/other; print '# new line from update' >> $base/other/README.md; git -C $base/other commit -qam two; git -C $base/other push -q; ~/.local/bin/agvim update --no-brew --no-tools 2>&1 | grep -E 'Updated|Done\.|error|couldn' ; tail -1 ~/clone/README.md; ls -a ~/clone/saved-projects | tr '\n' ' '; echo
echo "=== update blocked"; print 'mine' >> ~/clone/README.md; print '# conflict' >> $base/other/README.md; git -C $base/other commit -qam three; git -C $base/other push -q; print KEEP >> ~/clone/AGENTS.md;  ~/.local/bin/agvim update --no-brew --no-tools 2>&1 | tail -2 | cut -c1-120; echo "rc=${pipestatus[1]}"; 
echo "=== cli"; ~/.local/bin/agvim list; ~/.local/bin/agvim open /nope; echo rc=$?; ls ~/.local/bin | tr "\n" " "; echo; echo "=== help"; ~/.local/bin/agvim --help | head -2; ~/.local/bin/agvim nonsense >/dev/null; echo rc=$?
o kill-server 2>/dev/null; tmux -L projects kill-server 2>/dev/null; tmux kill-server 2>/dev/null
