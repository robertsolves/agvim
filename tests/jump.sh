#!/bin/zsh
# Ctrl-Space and the number it shows goes to a tab, project or worktree; a double-clicked tab,
# project or worktree gets a * and moves, closes and renames with keys (lib/jump).
src="${0:A:h:h}"
base=$(mktemp -d /tmp/awf.XXXX); base=${base:A}
export HOME=$base/home TMUX_TMPDIR=$base/t SHELL=/bin/zsh; mkdir -p $HOME/stubs $HOME/.local/bin $TMUX_TMPDIR ~/code/a ~/code/b; unset TMUX; touch ~/.zshrc
export AGVIM_REAL_TMUX="$(command -v tmux)"; cp "$src/tests/tmux-guard" $HOME/stubs/tmux; export PATH="$HOME/stubs:$PATH" # only this test's own servers, also if its folder goes
repo=$HOME/clone; mkdir -p $repo; (cd $src && git ls-files -co --exclude-standard -z | while IFS= read -r -d '' f; do [ -e "$f" ] && { mkdir -p "$repo/${f:h}"; cp -pR "$f" "$repo/$f"; }; done); git -C $repo init -q
ln -s $repo/bin/agvim ~/.local/bin/agvim; ln -s $repo/tmux/tmux.conf ~/.tmux.conf
for p in nvim lazygit; do print -l '#!/bin/zsh' '[[ "$*" == *--headless* ]] && exit 0' "exec -a $p sleep 1000" > ~/stubs/$p; chmod +x ~/stubs/$p; done
export PATH="$HOME/stubs:$HOME/.local/bin:$PATH"
# Every tmux of this test by its socket file: if something deletes the scratch folder
# (another run's clean-up), these fail instead of reaching the real workspace, and
# agvim isn't run at all.
sock=$TMUX_TMPDIR/tmux-$(id -u); mkdir -m 700 -p $sock
tmux() { command "$AGVIM_REAL_TMUX" -S $sock/default "$@"; }
o() { command "$AGVIM_REAL_TMUX" -S $sock/outer "$@"; }
b() { command "$AGVIM_REAL_TMUX" -S $sock/projects "$@"; }
av() { [ -x ~/stubs/tmux ] && [ -d $sock ] || { print -r -- "scratch folder gone: stopped"; exit 1; }; agvim "$@"; }
git config --global user.email t@t; git config --global user.name t; git config --global init.defaultBranch main
(cd ~/code/a && git init -q && print one > f && git add f && git commit -qm one)
print 'set -g default-terminal xterm-256color' > ~/outer.conf
screen() { o capture-pane -p -t o | sed -E 's/ +$//'; }
col() { perl -CS -Mutf8 -ne 'BEGIN { $w = shift } chomp; print index($_, $w) + 1' "$1"; } # a column, not a byte
upto() { local i; for i in {1..$1}; do eval "$2" && return; sleep .5; done; }
av new ~/code/b -n B --no-open
av new ~/code/a -n A --no-open
o -f ~/outer.conf new-session -d -s o -x 200 -y 30 "agvim open -p A; sleep 300"; o set -g status off
upto 60 "tmux has-session -t '=A' 2>/dev/null && [ \$(tmux list-windows -t '=A' | wc -l) -ge 3 ] && b list-clients 2>/dev/null | grep -q ."; sleep 1
b new-window -d -t '=projects:' -n B "$repo/lib/projects run B" # B's tab, not started
for i in {1..10}; do tmux new-window -d -t '=A:' -n "t$i" 'sleep 300'; done
win() { tmux display -p -t "=${1:-A}:" '#{window_index}'; }
keys() { o send-keys -t o "$@"; }
modes() { print "mode=$(tmux list-panes -a -F '#{pane_in_mode}' | sort -u | tr -d '\n') bar mode=$(b list-panes -a -F '#{pane_in_mode}' | sort -u | tr -d '\n')"; }
table() { tmux list-clients -F '#{client_key_table}' | tr -d '\n'; }
echo "windows: $(tmux list-windows -t '=A' | wc -l | tr -d ' ')"

echo "--- go"
keys C-Space 1 2; sleep 1; echo "Ctrl-Space 1 2: $(win)"
keys C-Space 3; sleep 1; echo "Ctrl-Space 3: $(win)"
keys C-Space 1; sleep 1.5; echo "Ctrl-Space 1, wait: $(win)"
keys C-Space 1; sleep 1; keys x; sleep .5; echo "digit after the wait types: $(tmux capture-pane -p -t '=A:' | grep -c x)"
# What AgVim's kitty sends for Cmd-1 Cmd-2, Cmd-3, Cmd-0 and Cmd-O 1 (macos/kitty.conf).
raw() { o send-keys -t o -H "$@"; }
raw 1b 31 1b 32; sleep 1; echo "Cmd-1 Cmd-2: $(win)"
raw 1b 33; sleep 1; echo "Cmd-3: $(win)"
raw 1b 31 1b 30; sleep 1; echo "Cmd-1 Cmd-0: $(win)"
raw 00 6f 31; sleep 1; echo "Cmd-O 1: $(b display -p -t '=projects:' '#{window_name}')"
raw 00 6f 32; sleep 1; echo "Cmd-O 2: $(b display -p -t '=projects:' '#{window_name}')"
keys C-Space o 1; sleep 1; echo "project 1: $(b display -p -t '=projects:' '#{window_name}')"
keys C-Space o 2; sleep 1; echo "project 2: $(b display -p -t '=projects:' '#{window_name}')"
av worktree fix -p A --agent none >/dev/null 2>&1; sleep 1.5
av worktree two -p A --agent none >/dev/null 2>&1; sleep 1.5
shown() { tmux list-clients -F '#{client_tty} #{session_name}' | awk -v t="$(b display -p -t '=projects:=A' '#{pane_tty}')" '$1 == t { print $2 }'; }
keys C-Space b 1; sleep 1.5; echo "worktree 1: $(shown)"
keys C-Space b 2; sleep 1.5; echo "worktree 2: $(shown)"
raw 00 62 33; sleep 1.5; echo "Cmd-B 3: $(shown)"
# Cmd-0 moves the numbers to the next row (tabs, worktrees, projects) and lights them
# there: dark on light (#e6e8eb), on that row only.
lit() { local r; for r in 1 3 30; do o capture-pane -e -p -t o | sed -n ${r}p | grep -q '48;2;230;232;235' && print -n "$r "; done; }
echo "lit at first: $(lit)"
raw 1b 30; sleep .5; echo "Cmd-0: $(tmux show -gv @area) $(b show -gv @area), lit: $(lit)"
raw 1b 32; sleep 1.5; echo "then Cmd-2: $(shown)"
raw 1b 30; sleep .5; echo "Cmd-0: $(tmux show -gv @area) $(b show -gv @area), lit: $(lit)"
raw 1b 31; sleep 1; echo "then Cmd-1: $(b display -p -t '=projects:' '#{window_name}')"
raw 1b 30; sleep .5; echo "Cmd-0: $(tmux show -gv @area) $(b show -gv @area), lit: $(lit)"
raw 1b 32; sleep 1; echo "then Cmd-2: $(tmux display -p -t '=agvim:' '#{window_index}') of $(tmux list-windows -t '=agvim' -F '#{window_index}:#{window_name}' | tr '\n' ' ')"
keys C-Space o 2; sleep 1.5; keys C-Space b 1; sleep 1.5
# Clicking a tab of a row makes the numbers go to that row, lit.
clk() { o send-keys -t o -l $'\e[<'"0;$1;$2M"$'\e[<'"0;$1;$2m"; sleep 1.5; }
clk $(screen | sed -n 3p | col main) 3; echo "click a worktree: $(tmux show -gv @area) $(b show -gv @area), lit: $(lit)"
clk $(( $(screen | sed -n 1p | col " A ") + 1 )) 1; echo "click a project: $(tmux show -gv @area) $(b show -gv @area), lit: $(lit)"
clk $(screen | sed -n 30p | col nvim) 30; echo "click a tab: $(tmux show -gv @area) $(b show -gv @area), lit: $(lit)"
modes
echo "numbers: project $(screen | sed -n 1p | grep -c '2 ● A') worktree $(screen | sed -n 3p | grep -c '2 ● ⎇ fix')"

echo "--- double-click a worktree"
row3() { screen | sed -n 3p; }
x=$(row3 | col fix)
dbl() { o send-keys -t o -l $'\e[<'"0;$1;$2M"$'\e[<'"0;$1;$2m"; sleep .05; o send-keys -t o -l $'\e[<'"0;$1;$2M"$'\e[<'"0;$1;$2m"; sleep 1.2; }
dbl $x 3; echo "worktree row: $(row3)"; row3 | grep -c 'fix\*' | xargs echo "fix has a *:"
keys Right; sleep 1.5; echo "order after Right: $(cut -f2 $repo/saved-projects/.worktrees/A | tr '\n' ,)"
keys Left; sleep 1.5; echo "order after Left: $(cut -f2 $repo/saved-projects/.worktrees/A | tr '\n' ,)"
keys Escape; sleep .5; row3 | grep -c '\*' | xargs echo "* after Escape:"

echo "--- double-click a project"
keys C-Space b 1; sleep 1.5
x=$(( $(screen | sed -n 1p | col " A ") + 1 ))
dbl $x 1; screen | sed -n 1p | grep -c ' A\*' | xargs echo "A has a *:"
keys Right; sleep .5; echo "bar after Right: $(b list-windows -t '=projects' -F '#{window_name}' | tr '\n' ,)"
keys Left; sleep .5; echo "bar after Left: $(b list-windows -t '=projects' -F '#{window_name}' | tr '\n' ,)"
keys Left; sleep .5; echo "agvim stays first: $(b list-windows -t '=projects' -F '#{window_name}' | tr '\n' ,)"
keys r; sleep .3; keys -l Apple; keys Enter; sleep 1.5
echo "renamed: $(b list-windows -t '=projects' -F '#{window_name}' | tr '\n' ,) session: $(tmux has-session -t '=Apple' 2>/dev/null && echo 1) saved: $([ -f $repo/saved-projects/Apple ] && echo 1)"
screen | sed -n 1p | grep -c '\*' | xargs echo "* after rename:"
modes

echo "--- double-click a tab"
keys C-Space 4; sleep 1
bottom() { screen | sed -n 30p; }
x=$(bottom | col "t2 "); echo "bottom row: $(bottom) x=$x"
echo "tab numbers: $(bottom | grep -c '13 ● t10')"
dbl $x 30; echo "tab: $(win Apple) $(bottom | grep -o 't2\*') table=$(table)"
keys Right; sleep .3; echo "t2 after Right: $(tmux display -p -t '=Apple:' '#{window_index} #{window_name}')"
keys Right; sleep .3; echo "t2 after Right again: $(tmux display -p -t '=Apple:' '#{window_index} #{window_name}')"
keys r; sleep .3; keys -l 'renamed "q'; keys Enter; sleep 1
echo "renamed tab: $(tmux display -p -t '=Apple:' '#{window_name} named=#{@named}') table=$(table)"
dbl $(bottom | col renamed) 30; keys r; sleep .3; keys Enter; sleep 1; echo "nothing typed keeps: $(tmux display -p -t '=Apple:' '#{window_name}')"
bottom | grep -c '\*' | xargs echo "* after rename:"
dbl $(bottom | col renamed) 30; keys BSpace; sleep 1; screen | grep -c 'Close renamed' | xargs echo "Delete asks:"
keys n; sleep .5
dbl $(bottom | col renamed) 30; keys a; sleep .3; bottom | grep -c '\*' | xargs echo "* after another key:"
tmux capture-pane -p -t '=Apple:' | grep -c '^a' | xargs echo "that key was eaten, typed:"
modes

echo "--- right-click menus"
x=$(bottom | col renamed); o send-keys -t o -l $'\e[<'"2;$x;30M"$'\e[<'"2;$x;30m"; sleep .5
m=$(screen); print -r -- "tab menu: rename $(print -r -- "$m" | grep -c Rename) colour $(print -r -- "$m" | grep -c Colour) move $(print -r -- "$m" | grep -c Move) close $(print -r -- "$m" | grep -c 'Close')"
keys Escape; sleep .3
x=$(( $(screen | sed -n 1p | col "Apple") + 1 )); o send-keys -t o -l $'\e[<'"2;$x;1M"$'\e[<'"2;$x;1m"; sleep .5
m=$(screen); print -r -- "project menu: colour $(print -r -- "$m" | grep -c Colour) move $(print -r -- "$m" | grep -c Move) close $(print -r -- "$m" | grep -c 'Close')"
keys Escape; sleep .3
modes

o kill-server; b kill-server; tmux kill-server # by socket file, see above
print $base
