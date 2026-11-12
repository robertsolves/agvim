#!/bin/zsh
# tests/run.sh [name...]: every test here, on separate tmux servers in scratch folders.
# Nothing touches the running workspace or Homebrew. A test passes when its log has
# every line it expects; logs stay in the folder this prints.
here="${0:A:h}"
root="${here:h}"
logs="$(mktemp -d /tmp/agvim-tests.XXXX)"
"$root/macos/bundle.sh" --app-only >/dev/null || { print -r -- "couldn't build the app"; exit 1; }

typeset -A expect=(
  full 'guard message: 1|^stopped|stub programs alive: 0|MARK-SHELL on screen: [1-9]|lazygit|agvim-kept|x on agvim: 0|deleted '
  app 'first run took|^ agvim|^  lazygit|click icon, running'
  menu 'open .*saved-projects|EXIT=0|Updated\.|couldn.t update|rc=1'
  name 'build server=1|build server named=1|while a program'
  bottom 'with few tabs: +2 -> +3'
  cli 'is now live|\(running\)|no such folder|not in a project|^worktree: branches|worktree help lines: [1-9]|last root removed, bytes left: 0$|agent tabs marked: 2'
  close 'reopened:.*lazygit.*keep me.*c,|Rename a project|asks: 1|window-style back: bg|take it out of A|back at menu after rename: 1|rename message shown|in picker: 1|back at menu after Esc in picker: 1|Esc at menu leaves, exit 0: 1|^AgVim by Robert|continue while it exists: 1|open a shell row: 0|last row: . Exit|exit row leaves: 1|continue once deleted: 0'
  ai 'mode 600|key on screen: 0|url=http://localhost:9/v1/chat/completions model=m1 key=secret-custom|loaded minuet provider=openai_compatible accept fn=function|provider=claude url=nil model=claude-haiku-5-5 key=secret-claude-key|model=some/model key=secret-groq-key|use=off copilot=false minuet=false|use=copilot copilot=true minuet=false|no AI source called nope'
  ai-suggest 'request: Bearer test-key-123 model=test-model|on screen: 1|in the file: 1'
  ai-providers 'claude key-sent=1 shown=1 in-file=1|openai key-sent=1 shown=1 in-file=1|gemini key-sent=1 shown=1 in-file=1|deepseek key-sent=1 shown=1 in-file=1|mistral key-sent=1 shown=1 in-file=1|groq key-sent=1 shown=1 in-file=1'
  site 'title: 51|description: 15[0-9]|canonical = og:url: yes|structured data: valid|every FAQ answer is on the page: yes|sitemap lists the page: yes|files exist: yes|side by side: 0'
  autoupdate 'clean clone moved to: v1.1.0|message: Updated to v1.1.0|new version runs: v1.1.0|your changes kept: 1|off stays on: v1.0.0|offline still opens: yes|already current stays: v1.1.0'
  keep 'bar still up: 1|A still running: 1|same lazygit: 1|tabs once: nvim,lazygit,shell 1,$|late tab saved: 1|bar tab kept: 1|A back: .*late tab|after crash: .*late tab|back to what.s running row: 1|shows off, still in the menu: 1|cursor on: > Keep terminals|setting off: 1|bar up: 0 A up: 0 scratch up: 1|adopted as tabs: 2|made before up: mine=1 shell7=1|B: nvim,lazygit,shell,shell, panes alive: 4|B after empty name: nvim,lazygit,shell,shell,|^agvim,A,$|^agvim,A2,$'
  agents 'different tab colours: 3|session: 1 parent=A|folder outside: a/fix-it|row shows it: 1|\+ Worktree button: 1|its tabs start with its branch: 1|merge asks: 1|commits in main after merge: 2|closed: 1 folder gone: 1|main.s tabs have no branch: 0|agent got: hello agent|agent got piped: from a pipe|shown after send: claude|pager taken as agent: 0|sent past the pager to: claude got: third|env copied: SECRET=1|unchanged: from main · 0 files|edited: from main · 1 file ·|close without asking: rc=2 env kept: SECRET=2|tab dot: done bar state: done|after looking: tab=\. bar state stays: done|mode=0 bar mode=0|running lists claude: 1|cargo test listed: 1|CLAUDE.md kept: x GEMINI.md: @AGENTS.md|Nothing changed|hi  \(mine\)|only that one: 0|after remove: 0|R saved: one=sess-one two=sess-two fb=fb-old|R back: claude --resume sess-one,claude --resume sess-two,freebuff --continue fb-old,|R without ids: claude,claude --continue,freebuff --continue,'
  jump 'Ctrl-Space 1 2: 12$|Ctrl-Space 3: 3$|Ctrl-Space 1, wait: 1$|Cmd-1 Cmd-2: 12$|Cmd-3: 3$|Cmd-1 Cmd-0: 10$|lit at first: 30 $|Cmd-0: worktree worktree, lit: 3 $|then Cmd-2: A-wt-fix$|Cmd-0: project project, lit: 1 $|then Cmd-1: agvim$|Cmd-0: tab tab, lit: 30 $|then Cmd-2: 2 of |click a worktree: worktree worktree, lit: 3 $|click a project: project project, lit: 1 $|click a tab: tab tab, lit: 30 $|Cmd-O 1: agvim$|Cmd-O 2: A$|Cmd-B 3: A-wt-two$|numbers: project 1 worktree 1|tab numbers: 1|tab menu: rename 1 colour 1 move 0 close 0|project menu: colour 1 move 0 close 0|project 2: A$|worktree 2: A-wt-fix$|fix has a \*: 1|order after Right: two,fix,$|order after Left: fix,two,$|\* after Escape: 0|A has a \*: 1|bar after Right: agvim,B,A,$|bar after Left: agvim,A,B,$|agvim stays first: agvim,A,B,$|renamed: agvim,Apple,B, session: 1 saved: 1|t2 after Right: 6 t2|renamed tab: renamed "q named=1|nothing typed keeps: renamed "q|Delete asks: 1|\* after another key: 0|eaten, typed: 0|^mode=0 bar mode=0$'
  up 'brew upgrade neovim|brew upgrade --cask kitty|MasonToolsUpdateSync|install rc=0'
)
# Whatever this test left behind: only its own servers, by their socket files. Never
# tmux -L with a TMUX_TMPDIR that may not exist: tmux then quietly uses /tmp's, the
# real workspace, and kill-server stops it. Folders made before the test, maybe
# another run's, are left alone.
clean_up() {
  local d sock
  for d in /tmp/awf.*(N/); do
    (( ${before[(Ie)$d]} )) && continue
    for sock in "$d"/tmux-*/*(N=) "$d"/t/tmux-*/*(N=); do
      tmux -S "$sock" kill-server 2>/dev/null
    done
    pkill -f "${d:A}" 2>/dev/null
    rm -rf "$d"
  done
}

failed=0
tests=("$@")
[ $# -gt 0 ] || tests=(site full app menu name bottom cli close keep agents jump ai ai-suggest ai-providers autoupdate up)
for t in "${tests[@]}"; do
  [ -f "$here/$t.sh" ] && [ -n "$expect[$t]" ] || { print -r -- "FAIL $t (no such test)"; failed=1; continue; }
  # Bounded, so a test that hangs can't stop the rest. Its servers end with it.
  before=(/tmp/awf.*(N/))
  perl -e 'alarm 240; exec @ARGV' /bin/zsh "$here/$t.sh" >"$logs/$t.log" 2>&1 </dev/null
  clean_up
  ok=1
  for line in ${(s:|:)expect[$t]}; do
    grep -qE -- "$line" "$logs/$t.log" || { ok=0; print -r -- "  $t: missing: $line"; }
  done
  if [ "$ok" = 1 ]; then print -r -- "pass $t"; else print -r -- "FAIL $t ($logs/$t.log)"; failed=1; fi
done
print -r -- "logs: $logs"
exit $failed
