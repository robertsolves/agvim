#!/bin/zsh
# Fresh install from a copy of the repo into a scratch HOME, real flow, then uninstall.
src="${0:A:h:h}"
base=$(mktemp -d /tmp/awf.XXXX); base=${base:A}
export HOME=$base/home TMUX_TMPDIR=$base/t SHELL=/bin/zsh
export AGVIM_REAL_TMUX="$(command -v tmux)"; mkdir -p $HOME/stubs; cp "$src/tests/tmux-guard" $HOME/stubs/tmux; export PATH="$HOME/stubs:$PATH" # only this test's own servers, also if its folder goes
mkdir -p $HOME $TMUX_TMPDIR; unset TMUX
repo=$HOME/clone; mkdir -p $repo
(cd $src && git ls-files -co --exclude-standard -z | while IFS= read -r -d '' f; do [ -e "$f" ] && { mkdir -p "$repo/${f:h}"; cp -pR "$f" "$repo/$f"; }; done)
git -C $repo init -q
mkdir -p ~/.config/kitty ~/Work/alpha ~/Work/beta; git -C ~/Work/alpha init -q; mkdir -p "$HOME/Work/My App"; print -l '# mine' '# agent-workspace (Option as Alt)' 'include agent-workspace.conf' > ~/.config/kitty/kitty.conf; ln -s $repo/kitty/startup-session.conf ~/.config/kitty/startup-session.conf
mkdir -p ~/.config/nvim; print 'my nvim' > ~/.config/nvim/init.lua   # a real prior config
touch ~/.zshrc
export PATH="$HOME/.local/bin:$HOME/stubs:$PATH"
mkdir -p ~/stubs
print -l '#!/bin/zsh' 'print open "$@" >> $HOME/open.log' > ~/stubs/open; chmod +x ~/stubs/open
print 'set -g default-terminal xterm-256color' > ~/outer.conf
for p in nvim claude lazygit; do print -l '#!/bin/zsh' '[[ "$*" == *--headless* ]] && exit 0' "print started $p \"\$@\" >> \$HOME/started.log" "exec -a $p sleep 1000" > ~/stubs/$p; chmod +x ~/stubs/$p; done
(cd $repo && ./install.sh --no-brew --no-tools 2>&1 | grep -E 'backup|launch|!|plugins' )
ls ~/Library/Services
OC="agvim open"
o() { tmux -L outer "$@"; }; b() { tmux -L projects "$@"; }
shot() { echo "----- $1"; o capture-pane -p -t o | sed -E 's/ +$//' | awk 'NF' | cut -c1-108 | head -${2:-5}; }
click() { o send-keys -t o -l $'\e[<'"0;$1;$2M"; o send-keys -t o -l $'\e[<'"0;$1;$2m"; sleep ${3:-1}; }
ostart() { o -f ~/outer.conf new-session -d -s o -x 110 -y 30 "$OC; print BACK-IN-SHELL; sleep 100"; o set -g status off; sleep 2; }
ostart; shot "first run: picker" 8
o send-keys -t o Escape; sleep 1; shot "esc: back in shell" 2; o kill-server; sleep 0.5; echo "kitty after install:"; cat ~/.config/kitty/kitty.conf; ls ~/.config/kitty

key() { o send-keys -t o "$@"; sleep ${W:-0.6}; }
txt() { o send-keys -t o -l "$1"; sleep 0.5; }
top() { o capture-pane -p -t o | sed -E 's/ +$//' | sed -n 1p; }
plus_project() { t=$(top); click $(( ${#t} - 13 )) 1 1.5; }  # inside "+ Project"
plus_shell() { t=$(top); click $(( ${#t} - 3 )) 1 1.5; }
tabclick() { t=$(top); i=${t[(i)$1]}; click $((i+1)) 1 1.5; }
store=$repo/saved-projects

ostart
txt ""; key Enter; txt Work; key Enter; txt alpha; key Enter; key Enter; txt "Alpha"; W=1 key Enter
for _ in {1..40}; do [[ "$(top)" == *Alpha* ]] && break; sleep .25; done # the workspace opens in a few seconds on a busy Mac
shot "project Alpha created from the picker" 3
echo "saved: $(agvim list)"; cat ~/started.log
plus_shell; shot "+ Shell" 3
txt "echo MARK-SHELL"; key Enter
tabclick Alpha; sleep 0.5; tmux select-window -t '=Alpha:=shell 1'; sleep 0.5
txt "echo MARK-ALPHA"; key Enter; tmux split-window -t '=Alpha:=shell 1' -c ~/Work; sleep 0.5
tmux new-window -d -t '=Alpha:' -n claude 'claude; true'; sleep 0.5
plus_project; shot "popup in Alpha" 7
key Down; key Enter; txt Work; key Enter; txt beta; key Enter; W=2 key Enter
echo "after add:"; agvim list; tmux list-windows -t '=Alpha' -F '  #{window_name} folder=#{@folder} panes=#{window_panes}'
echo "--- new shell from beta tab starts in beta"; ~/.local/bin/agvim _tab new "$(tmux display -p -t '=Alpha:' '#{session_id}')"; sleep 0.5; tmux list-panes -s -t '=Alpha' -F '  #{window_name} #{pane_current_path} active=#{window_active}'
echo "--- first-time tabs in a repo"; tmux list-windows -t '=Alpha' -F '  #{window_name}'; echo "--- Alt keys"; n1=$(tmux list-windows -t '=Alpha' | wc -l); key M-t; n2=$(tmux list-windows -t '=Alpha' | wc -l); echo "Alt-t windows $n1 -> $n2"; b select-window -t '=projects:=Alpha'; sleep .4; a1=$(b display -p -t '=projects:' '#W'); o send-keys -t o -l $'\e}'; sleep 0.6; a2=$(b display -p -t '=projects:' '#W'); echo "Alt-Shift-] $a1 -> $a2"; b select-window -t '=projects:=Alpha'; sleep 1
echo "--- second workspace inside it"; agvim list >/dev/null; txt "agvim continue"; key Enter; sleep 0.5; o capture-pane -p -t o | grep -c 'open already' | xargs echo "guard message:"
echo "--- Finder with bar open"; ~/.local/bin/agvim _project add --window Alpha ~/Work/beta; cat ~/open.log 2>/dev/null; tmux kill-window -t '=Alpha:=lazygit'; sleep .3; echo "--- close Alpha with x (lazygit tab closed first)"; t=$(top); i=${t[(i)Alpha]}; click $((i+7)) 1 1; shot "prompt" 2; key y; sleep 1.5; tmux has-session -t '=Alpha' 2>/dev/null && echo STILL-RUNNING || echo stopped; live=" $(tmux list-panes -a -F '#{pane_tty}' 2>/dev/null | tr '\n' ' ') "; n=0; for p in $(pgrep -f '^(claude|nvim) 1000'); do [[ "$live" == *" /dev/$(ps -o tty= -p $p | tr -d ' ') "* ]] || n=$((n + 1)); done; echo "stub programs alive: $n" # not counting other projects' (closing Alpha shows agvim's tab, which starts it); cat $store/.tabs/Alpha/tabs | cut -f1,2,5,6,8; ls -ld $store/.tabs/Alpha | cut -c1-10; shot "bar after close" 2
echo "--- reopen Alpha from the picker"; : > ~/started.log; plus_project; txt Alpha; W=2.5 key Enter; tmux list-windows -t '=Alpha' -F '  #{window_name} folder=#{@folder} panes=#{window_panes} active=#{window_active}'; cat ~/started.log; tmux capture-pane -p -t '=Alpha:=shell 1.1' | grep -c MARK-ALPHA | xargs echo "MARK-ALPHA lines:"
echo "--- quit kitty (client killed)"; pid=$(b list-clients -F '#{client_pid}'); kill -HUP $pid; sleep 3.5; o kill-server 2>/dev/null; sleep 0.5; tmux ls 2>&1 | head -1; b ls 2>&1 | head -1; echo "open: $(tr '\n' ',' < $store/.open) active: $(<$store/.active)"
echo "--- Finder with nothing open"; print /Applications/Fake.app > $store/.terminal; mkdir -p /tmp/noop; agvim _open-project --window ~/Work/beta; cat ~/open.log | tail -2; ls $repo/saved-projects/.open-agvim.command; cat $store/.open-agvim.command; tmux kill-server 2>/dev/null; b kill-server 2>/dev/null; sleep 0.3
echo "--- reopen workspace"; OC="agvim continue"; : > ~/started.log; ostart; sleep 1.5; shot "bar back" 2; echo "running: $(tmux list-sessions -F '#{session_name}' | tr '\n' ',')"; cat ~/started.log
tabclick "Shell 1"; for _ in {1..30}; do o capture-pane -p -t o | grep -q MARK-SHELL && break; sleep .2; done; echo "running: $(tmux list-sessions -F '#{session_name}' | tr '\n' ',')"; o capture-pane -p -t o | grep -c MARK-SHELL | xargs echo "MARK-SHELL on screen:"
echo "--- close Shell 1 discards it"; t=$(top); i=${t[(i)Shell 1]}; click $((i+9)) 1 1; key y; sleep 1.5; ls $store/.tabs; shot bar 1
echo "--- agvim tab"; t=$(top); print -r -- "$t" | cut -c1-40; print -r -- "$t" | awk -F'│' '{ print $1 }' | grep -c '󰅖' | xargs echo "x on agvim:"; agvim delete agvim; echo rc=$?; b list-windows -F '#{window_index} #{window_name}' | head -1; tmux has-session -t '=agvim' 2>/dev/null && echo agvim-kept || echo agvim-gone; tabclick agvim; sleep 1; tmux list-windows -t '=agvim' -F '  #{window_name} #{pane_current_path}'; tabclick Alpha
echo "--- name guard"; agvim delete ../.. ; echo rc=$?; agvim delete; echo rc=$?; ls -d $store
echo "--- overflow with buttons"; for n in {1..9}; do agvim shell; sleep 0.2; done; b select-window -t '=projects:1'; sleep 0.5; shot start 1; click 89 1; echo "cur=$(b display -p -t '=projects:' '#{window_index}')"; click 89 1; echo "cur=$(b display -p -t '=projects:' '#{window_index}') mode=$(b display -p -t '=projects:' '#{pane_in_mode}')"; shot after 1
b kill-server; tmux kill-server; o kill-server; sleep 0.5
echo "===== uninstall"; ( cd $repo && ./uninstall.sh --yes 2>&1 | grep -vE '^$' | cut -c1-100 )
echo "after:"; ls -la ~/.config/nvim | head -3 | cut -c30-; cat ~/.config/nvim/init.lua; cat ~/.config/kitty/kitty.conf; ls ~/.config/kitty ~/Library/Services; ls ~/.local/bin 2>/dev/null | wc -l; ls ~/.tmux.conf 2>&1 | cut -c1-40; ls $repo | head -3; ls -a $repo | grep saved; ls ~/Work
( $repo/uninstall.sh --yes --delete-repo 2>&1 | tail -3 | cut -c1-80 ); ls $HOME | tr '\n' ' '; echo; echo "base=$base"
