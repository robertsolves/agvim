#!/bin/zsh
# The agent features: worktrees (new, the row, merge, close), send, the needs-you dot,
# tab colours, the running list, init and the skills library.
src="${0:A:h:h}"
base=$(mktemp -d /tmp/awf.XXXX); base=${base:A}
export HOME=$base/home TMUX_TMPDIR=$base/t SHELL=/bin/zsh; mkdir -p $HOME/stubs $HOME/.local/bin $TMUX_TMPDIR ~/code/a; unset TMUX; touch ~/.zshrc
repo=$HOME/clone; mkdir -p $repo; (cd $src && git ls-files -co --exclude-standard -z | while IFS= read -r -d '' f; do [ -e "$f" ] && { mkdir -p "$repo/${f:h}"; cp -pR "$f" "$repo/$f"; }; done); git -C $repo init -q
ln -s $repo/bin/agvim ~/.local/bin/agvim; ln -s $repo/tmux/tmux.conf ~/.tmux.conf
for p in nvim lazygit; do print -l '#!/bin/zsh' '[[ "$*" == *--headless* ]] && exit 0' "exec -a $p sleep 1000" > ~/stubs/$p; chmod +x ~/stubs/$p; done
# An agent that shows what's typed into it, line by line, in a file.
print -l '#!/bin/zsh' 'while IFS= read -r l; do print -r -- "$l" >> ~/claude-got; done' > ~/stubs/claude; chmod +x ~/stubs/claude
print -l '#!/bin/zsh' 'exit 0' > ~/stubs/osascript; chmod +x ~/stubs/osascript
[ -n "$AGVIM_TEST_TMUX" ] && cp "$AGVIM_TEST_TMUX" ~/stubs/tmux
export PATH="$HOME/stubs:$HOME/.local/bin:$PATH"
git config --global user.email t@t; git config --global user.name t; git config --global init.defaultBranch main
(cd ~/code/a && git init -q && print one > f && git add f && git commit -qm one)
print 'set -g default-terminal xterm-256color' > ~/outer.conf
o() { tmux -L outer "$@"; }; b() { tmux -L projects "$@"; }
screen() { o capture-pane -p -t o | sed -E 's/ +$//'; }
agvim new ~/code/a -n A --no-open
o -f ~/outer.conf new-session -d -s o -x 140 -y 30 "agvim open -p A; sleep 300"; o set -g status off; sleep 3

echo "--- colours"
tmux list-windows -t "=A" -F "#{@colour}" | sort -u | grep -c . | xargs echo "different tab colours:"
echo "bar colour: $(b show -wv -t '=projects:=A' @colour)"

echo "--- worktree"
agvim worktree fix-it -p A --agent none; sleep 1.5
echo "session: $(tmux has-session -t '=A-wt-fix-it' 2>/dev/null && echo 1 || echo 0) parent=$(tmux show -qv -t '=A-wt-fix-it:' @parent)"
d=$(cut -f3 $repo/saved-projects/.worktrees/A); echo "folder outside: ${d#$HOME/.local/share/agvim/worktrees/}"
echo "branch: $(git -C $d branch --show-current)"
screen | grep -c 'fix-it' | xargs echo "row shows it:"
screen | grep -c 'Worktree' | xargs echo "+ Worktree button:"
agvim worktree list -p A | cut -d' ' -f1-3
(cd $d && print two >> f && git commit -qam two)
o new-window -d -t 'o:' -n m "env -u TMUX agvim worktree merge -p A; sleep 30"; sleep 1.5
o capture-pane -p -t 'o:=m' | grep -c 'Merging fix-it into main' | xargs echo "merge asks:"; o send-keys -t 'o:=m' Enter; sleep 1.5
git -C ~/code/a log --oneline | wc -l | tr -d ' ' | xargs echo "commits in main after merge:"
agvim worktree close fix-it -p A </dev/null >/dev/null 2>&1; sleep .5
echo "closed: $(tmux has-session -t '=A-wt-fix-it' 2>/dev/null && echo 0 || echo 1) folder gone: $([ -d $d ] && echo 0 || echo 1)"

echo "--- send"
tmux new-window -d -t '=A:' -n claude -c ~/code/a 'claude; true'; tmux set -w -t '=A:=claude' @agent claude; sleep .5
agvim send -p A 'hello agent'; sleep .3; tmux send-keys -t '=A:=claude' Enter; sleep .5
echo "agent got: $(cat ~/claude-got 2>/dev/null)"
print 'from a pipe' | agvim send -p A; sleep .3; tmux send-keys -t '=A:=claude' Enter; sleep .5
echo "agent got piped: $(tail -1 ~/claude-got 2>/dev/null)"
echo "shown after send: $(tmux display -p -t '=A:' '#W')"

echo "--- attention"
tmux select-window -t '=A:=nvim'; sleep .3
TMUX_PANE=$(tmux display -p -t '=A:=claude' '#{pane_id}') agvim _attention set done; sleep .3
echo "tab dot: $(tmux show -wqv -t '=A:=claude' @attention) bar state: $(b show -wqv -t '=projects:=A' @agent-state)"
tmux select-window -t '=A:=claude'; agvim _attention sync; sleep .3
echo "after looking: tab=$(tmux show -wqv -t '=A:=claude' @attention). bar state stays: $(b show -wqv -t '=projects:=A' @agent-state)."
echo "mode=$(tmux display -p -t '=A:' '#{pane_in_mode}') bar mode=$(b display -p -t '=projects:' '#{pane_in_mode}')"

echo "--- running"
agvim agents --running --print | grep -c claude | xargs echo "running lists claude:"

echo "--- init"
mkdir ~/code/r && print '[package]' > ~/code/r/Cargo.toml && print 'x' > ~/code/r/CLAUDE.md
agvim init ~/code/r; grep -c 'cargo test' ~/code/r/AGENTS.md | xargs echo "cargo test listed:"
echo "CLAUDE.md kept: $(cat ~/code/r/CLAUDE.md) GEMINI.md: $(cat ~/code/r/GEMINI.md)"
agvim init ~/code/r

echo "--- skills"
lib=~/mylib; mkdir -p $lib/commands $lib/skills/tidy; print 'Say hi.' > $lib/commands/hi.md; print -- '---\nname: tidy\n---\nTidy up.' > $lib/skills/tidy/SKILL.md
mkdir -p ~/.config/agvim; print -l "mine	$lib" > ~/.config/agvim/library
agvim skills add hi -C ~/code/a; agvim skills list -C ~/code/a
echo "only that one: $(ls ~/code/a/.agents/*(N) ~/code/a/.agents/*/*(N) 2>/dev/null | grep -c tidy)"
agvim skills remove hi -C ~/code/a; echo "after remove: $(agvim skills list -C ~/code/a | wc -l | tr -d ' ')"
o kill-server 2>/dev/null; b kill-server 2>/dev/null; tmux kill-server 2>/dev/null
