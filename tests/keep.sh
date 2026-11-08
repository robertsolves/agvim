#!/bin/zsh
# Closing the window leaves everything running (keep-running, on by default), and
# every way of closing comes back right: reattach, stop, a crash, one session lost.
src="${0:A:h:h}"
base=$(mktemp -d /tmp/awf.XXXX); base=${base:A}
export HOME=$base/home TMUX_TMPDIR=$base/t SHELL=/bin/zsh; mkdir -p $HOME/stubs $HOME/.local/bin $TMUX_TMPDIR ~/code/a ~/code/b; unset TMUX; touch ~/.zshrc
export AGVIM_REAL_TMUX="$(command -v tmux)"; mkdir -p $HOME/stubs; cp "$src/tests/tmux-guard" $HOME/stubs/tmux; export PATH="$HOME/stubs:$PATH" # only this test's own servers, also if its folder goes
repo=$HOME/clone; mkdir -p $repo; (cd $src && git ls-files -co --exclude-standard -z | while IFS= read -r -d '' f; do [ -e "$f" ] && { mkdir -p "$repo/${f:h}"; cp -pR "$f" "$repo/$f"; }; done); git -C $repo init -q
ln -s $repo/bin/agvim ~/.local/bin/agvim; ln -s $repo/tmux/tmux.conf ~/.tmux.conf
for p in nvim lazygit; do print -l '#!/bin/zsh' '[[ "$*" == *--headless* ]] && exit 0' "exec -a $p sleep 1000" > ~/stubs/$p; chmod +x ~/stubs/$p; done
[ -n "$AGVIM_TEST_TMUX" ] && cp "$AGVIM_TEST_TMUX" ~/stubs/tmux # a wrapper, for a tmux that prints tabs as _
export PATH="$HOME/stubs:$HOME/.local/bin:$PATH"
print 'set -g default-terminal xterm-256color' > ~/outer.conf
o() { tmux -L outer "$@"; }; b() { tmux -L projects "$@"; }
win() { tmux list-windows -t "=${1:-A}" -F '#W' 2>&1 | tr '\n' ',' ; echo; }
upto() { local i; for i in {1..$1}; do eval "$2" && return; sleep .5; done; } # waits for a check, so a busy Mac doesn't fail it
window() { o -f ~/outer.conf new-session -d -s o -x 120 -y 30 "$1; sleep 300"; o set -g status off; upto 60 "b list-clients 2>/dev/null | grep -q ."; sleep 3; }
closewin() { kill -HUP $(b list-clients -F '#{client_pid}') 2>/dev/null; sleep 2.5; o kill-server 2>/dev/null; sleep .3; }
agvim new ~/code/a -n A --no-open; agvim new ~/code/b -n B --no-open

echo "--- close the window, keep running on"
window "agvim open -p A"; pid=$(pgrep -f 'lazygit' | head -1)
closewin
echo "bar still up: $(b has-session -t '=projects' 2>/dev/null && echo 1 || echo 0)"
echo "A still running: $(tmux has-session -t '=A' 2>/dev/null && echo 1 || echo 0)"
echo "--- open again"
window "agvim continue"
echo "same lazygit: $([ "$(pgrep -f lazygit | head -1)" = "$pid" ] && echo 1 || echo 0)"
echo "tabs once: $(win)"; echo "bar tabs: $(b list-windows -t '=projects' -F '#W' | tr '\n' ',')"

echo "--- a tab added is saved within seconds"
tmux new-window -d -t '=A:' -n "late tab" -c ~/code/a; sleep 5
grep -c 'late tab' $repo/saved-projects/.tabs/A/tabs | xargs echo "late tab saved:"

echo "--- one session lost while the bar is up comes back from its save"
tmux kill-session -t '=A'; sleep 1
echo "bar tab kept: $(b list-windows -t '=projects' -F '#W' | grep -cx A)"
b select-window -t '=projects:=A'; sleep 2.5
echo "A back: $(win)"

echo "--- a crash: both servers gone at once"
b kill-server; tmux kill-server; sleep .5
o kill-server 2>/dev/null; window "agvim continue"; upto 20 "b list-windows -t '=projects' -F '#W' | grep -qx A"; b select-window -t '=projects:=A'; upto 40 "win | grep -q 'late tab'"
echo "after crash: $(win)"

echo "--- the menu's switch"
closewin
o -f ~/outer.conf new-session -d -s o -x 120 -y 30 "agvim; print EXIT=\$?; sleep 60"; o set -g status off; sleep 1.5
o capture-pane -p -t o | grep -c 'Back to what.s running' | xargs echo "back to what's running row:"
o send-keys -t o -l 'Keep terminals'; sleep .4; o send-keys -t o Enter; sleep 1
o capture-pane -p -t o | grep -c 'Keep terminals running after closing  \[off\]' | xargs echo "shows off, still in the menu:"
echo "setting off: $([ -f ~/.config/agvim/keep-running-off ] && echo 1 || echo 0)"
# Back on the same row: Enter alone flips it again (fzf's pointer looks like its gutter,
# so the screen can't show which row it's on). Then off again for what follows.
o send-keys -t o Enter; sleep 1; echo "cursor on: $([ -f ~/.config/agvim/keep-running-off ] && echo other row || echo "> Keep terminals")"
o send-keys -t o Enter; sleep 1
o send-keys -t o Escape; sleep .5; o kill-server; sleep .3

echo "--- keep running off: closing stops AgVim's sessions, not yours"
window "agvim continue"; tmux new-session -d -s scratch 'sleep 999' # yours, made after AgVim opened
closewin; sleep 1
echo "bar up: $(b has-session -t '=projects' 2>/dev/null && echo 1 || echo 0) A up: $(tmux has-session -t '=A' 2>/dev/null && echo 1 || echo 0) scratch up: $(tmux has-session -t '=scratch' 2>/dev/null && echo 1 || echo 0)"
agvim keep-running on >/dev/null

echo "--- empty tab name and a removed agent still restore"
mkdir -p $repo/saved-projects/.tabs/B; print -r -- "1	nvim	1	-	-	1	$HOME/code/b	nvim	-	-
2	shell	0	-	-	1	$HOME/code/b	ghostagent	-	-
3	shell	0	-	-	1	-	-	-	-" > $repo/saved-projects/.tabs/B/tabs
agvim _project start B; sleep 1; echo "B: $(win B) panes alive: $(tmux list-panes -s -t '=B' -F '#{pane_dead}' | grep -c 0)"
tmux rename-window -t '=B:3' ""; agvim _project save B; agvim _project close B; agvim _project start B; sleep .5; echo "B after empty name: $(win B)"

echo "--- closing or renaming with the bar down keeps 'continue'"
print -l agvim A B > $repo/saved-projects/.open
agvim _project close B; tr '\n' ',' < $repo/saved-projects/.open; echo
agvim rename A2 -p A >/dev/null; tr '\n' ',' < $repo/saved-projects/.open; echo
o kill-server 2>/dev/null; b kill-server 2>/dev/null; tmux kill-server 2>/dev/null
