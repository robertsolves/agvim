#!/bin/zsh
# The agent features: worktrees (new, the row, merge, close), send, the needs-you dot,
# tab colours, the running list, init and the skills library.
src="${0:A:h:h}"
base=$(mktemp -d /tmp/awf.XXXX); base=${base:A}
export HOME=$base/home TMUX_TMPDIR=$base/t SHELL=/bin/zsh; mkdir -p $HOME/stubs $HOME/.local/bin $TMUX_TMPDIR ~/code/a; unset TMUX; touch ~/.zshrc
export AGVIM_REAL_TMUX="$(command -v tmux)"; mkdir -p $HOME/stubs; cp "$src/tests/tmux-guard" $HOME/stubs/tmux; export PATH="$HOME/stubs:$PATH" # only this test's own servers, also if its folder goes
repo=$HOME/clone; mkdir -p $repo; (cd $src && git ls-files -co --exclude-standard -z | while IFS= read -r -d '' f; do [ -e "$f" ] && { mkdir -p "$repo/${f:h}"; cp -pR "$f" "$repo/$f"; }; done); git -C $repo init -q
ln -s $repo/bin/agvim ~/.local/bin/agvim; ln -s $repo/tmux/tmux.conf ~/.tmux.conf
for p in nvim lazygit; do print -l '#!/bin/zsh' '[[ "$*" == *--headless* ]] && exit 0' "exec -a $p sleep 1000" > ~/stubs/$p; chmod +x ~/stubs/$p; done
# An agent that shows what's typed into it, line by line, in a file.
# Named claude in ps, as the real one is, so AgVim sees it as Claude.
print -l '#!/bin/zsh' 'print -r -- "claude $*" >> ~/agent-args' "exec -a claude zsh -c 'while IFS= read -r l; do print -r -- \"\$l\" >> ~/claude-got; done'" > ~/stubs/claude; chmod +x ~/stubs/claude
# Freebuff keeps its chat's log open, so the stub does too.
print -l '#!/bin/zsh' 'print -r -- "freebuff $*" >> ~/agent-args' 'mkdir -p ~/fb/chats/${2:-fb-new}; exec 3>>~/fb/chats/${2:-fb-new}/log.jsonl; exec -a freebuff sleep 1000' > ~/stubs/freebuff; chmod +x ~/stubs/freebuff
print -l '#!/bin/zsh' 'exit 0' > ~/stubs/osascript; chmod +x ~/stubs/osascript
[ -n "$AGVIM_TEST_TMUX" ] && cp "$AGVIM_TEST_TMUX" ~/stubs/tmux
export PATH="$HOME/stubs:$HOME/.local/bin:$PATH"
git config --global user.email t@t; git config --global user.name t; git config --global init.defaultBranch main
(cd ~/code/a && git init -q && print one > f && git add f && git commit -qm one)
print 'set -g default-terminal xterm-256color' > ~/outer.conf
o() { tmux -L outer "$@"; }; b() { tmux -L projects "$@"; }
screen() { o capture-pane -p -t o | sed -E 's/ +$//'; }
upto() { local i; for i in {1..$1}; do eval "$2" && return; sleep .5; done; } # waits for a check, so a busy Mac doesn't fail it
agvim new ~/code/a -n A --no-open
o -f ~/outer.conf new-session -d -s o -x 140 -y 30 "agvim open -p A; sleep 300"; o set -g status off
upto 60 "b show -wv -t '=projects:=A' @colour 2>/dev/null | grep -q . && [ \$(tmux list-windows -t '=A' -F '#{@colour}' 2>/dev/null | sort -u | grep -c .) -ge 3 ]"; sleep 1

echo "--- colours"
tmux list-windows -t "=A" -F "#{@colour}" | sort -u | grep -c . | xargs echo "different tab colours:"
echo "bar colour: $(b show -wv -t '=projects:=A' @colour)"

echo "--- worktree"
agvim worktree fix-it -p A --agent none; sleep 1.5
echo "session: $(tmux has-session -t '=A-wt-fix-it' 2>/dev/null && echo 1 || echo 0) parent=$(tmux show -qv -t '=A-wt-fix-it:' @parent)"
d=$(cut -f3 $repo/saved-projects/.worktrees/A); echo "folder outside: ${d#$HOME/.local/share/agvim/worktrees/}"
echo "branch: $(git -C $d branch --show-current)"
screen | sed -n 3p | grep -c 'fix-it' | xargs echo "row shows it:"
screen | grep -c 'Worktree' | xargs echo "+ Worktree button:"
screen | tail -1 | grep -c '^  ⎇ fix-it │' | xargs echo "its tabs start with its branch:"
agvim worktree list -p A | cut -d' ' -f1-3
(cd $d && print two >> f && git commit -qam two)
o new-window -d -t 'o:' -n m "env -u TMUX agvim worktree merge -p A; sleep 30"; sleep 1.5
o capture-pane -p -t 'o:=m' | grep -c 'Merging fix-it into main' | xargs echo "merge asks:"; o send-keys -t 'o:=m' Enter; sleep 1.5
git -C ~/code/a log --oneline | wc -l | tr -d ' ' | xargs echo "commits in main after merge:"
agvim worktree close fix-it -p A </dev/null >/dev/null 2>&1; sleep .5
echo "closed: $(tmux has-session -t '=A-wt-fix-it' 2>/dev/null && echo 0 || echo 1) folder gone: $([ -d $d ] && echo 0 || echo 1)"
screen | tail -1 | grep -c '⎇' | xargs echo "main's tabs have no branch:"

echo "--- send"
tmux new-window -d -t '=A:' -n claude -c ~/code/a 'claude; true'; tmux set -w -t '=A:=claude' @agent claude; sleep .5
agvim send -p A 'hello agent'; sleep .3; tmux send-keys -t '=A:=claude' Enter; sleep .5
echo "agent got: $(cat ~/claude-got 2>/dev/null)"
print 'from a pipe' | agvim send -p A; sleep .3; tmux send-keys -t '=A:=claude' Enter; sleep .5
echo "agent got piped: $(tail -1 ~/claude-got 2>/dev/null)"
echo "shown after send: $(tmux display -p -t '=A:' '#W')"
# A program that isn't an agent, looked at last, doesn't get what's sent.
tmux new-window -d -t '=A:' -n pager 'cat'; sleep .5; tmux select-window -t '=A:=pager'; agvim _attention sync; sleep .3
echo "pager taken as agent: $([ "$(tmux show -qv -t '=A' @last-agent)" = "$(tmux display -p -t '=A:=pager' '#{window_id}')" ] && echo 1 || echo 0)"
agvim send -p A 'third'; sleep .3; tmux send-keys -t '=A:=claude' Enter; sleep .5
echo "sent past the pager to: $(tmux display -p -t '=A:' '#W') got: $(tail -1 ~/claude-got 2>/dev/null)"
tmux kill-window -t '=A:=pager'

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

echo "--- each agent tab comes back as its own conversation"
mkdir -p ~/code/res; agvim new ~/code/res -n R --no-open; $repo/lib/project start R >/dev/null 2>&1; upto 40 "tmux has-session -t '=R' 2>/dev/null"
for t in one two; do tmux new-window -d -t '=R:' -n $t 'claude; exec zsh'; done; tmux new-window -d -t '=R:' -n fb 'freebuff --continue fb-old; exec zsh'; sleep 1
for t in one two; do printf '{"session_id":"sess-%s","prompt":"a, {b}"}' $t | TMUX_PANE=$(tmux display -p -t "=R:=$t" '#{pane_id}') agvim _attention clear; done
back() { : > ~/agent-args; $repo/lib/project start R >/dev/null 2>&1; upto 40 "grep -q freebuff ~/agent-args"; sleep 1; sed -E 's/ --settings [^ ]*//' ~/agent-args | LC_ALL=C sort | tr '\n' ','; echo; }
$repo/lib/project close R </dev/null >/dev/null 2>&1
echo "R saved: $(awk -F'\t' '$8 != "-" && $8 != "nvim" && $8 != "lazygit" { printf "%s=%s ", $2, $12 }' $repo/saved-projects/.tabs/R/tabs)"
echo "R back: $(back)"
$repo/lib/project close R </dev/null >/dev/null 2>&1; f=$repo/saved-projects/.tabs/R/tabs; cut -f1-11 $f > $f.n && mv $f.n $f # saved before AgVim kept ids
echo "R without ids: $(back)"

echo "--- closing a worktree keeps an edited .env"
(cd ~/code/a && print .env > .gitignore && print .env > .worktreeinclude && print SECRET=1 > .env && git add .gitignore .worktreeinclude && git commit -qm ignore)
agvim worktree envy -p A --agent none; sleep 1.5
d=$(awk -F'\t' '$2 == "envy" { print $3 }' $repo/saved-projects/.worktrees/A)
echo "env copied: $(cat $d/.env)"
echo "unchanged: $(agvim _worktree stat $d main)"
print SECRET=2 > $d/.env
echo "edited: $(agvim _worktree stat $d main)"
agvim worktree close envy -p A </dev/null >/dev/null 2>&1; echo "close without asking: rc=$? env kept: $(cat $d/.env 2>/dev/null)"
o kill-server 2>/dev/null; b kill-server 2>/dev/null; tmux kill-server 2>/dev/null
