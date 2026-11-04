#!/bin/zsh
# tests/run.sh [name...]: every test here, on separate tmux servers in scratch folders.
# Nothing touches the running workspace or Homebrew. A test passes when its log has
# every line it expects; logs stay in the folder this prints.
here="${0:A:h}"
root="${here:h}"
logs="$(mktemp -d /tmp/agentnv-tests.XXXX)"
"$root/macos/bundle.sh" --app-only >/dev/null || { print -r -- "couldn't build the app"; exit 1; }

typeset -A expect=(
  full 'guard message: 1|^stopped|stub programs alive: 0|MARK-SHELL on screen: [1-9]|lazygit|agentnv-lazy|deleted '
  app 'first run took|^ agentnv|^  lazygit|click icon, running'
  menu 'EXIT=0|Updated\.|couldn.t update|rc=1'
  name 'build server=1|build server named=1|while a program'
  bottom 'with few tabs: +2 -> +3'
  cli 'is now live|\(running\)|no such folder|not in a project'
  close 'reopened:.*lazygit.*keep me.*c,|Rename a project|asks: 1|window-style back: bg|take it out of A|back at menu after rename: 1|rename message shown|in picker: 1|back at menu after Esc in picker: 1|Esc at menu leaves, exit 0: 1|^AgentNV by Robert'
  ai 'mode 600|key on screen: 0|url=http://localhost:9/v1/chat/completions model=m1 key=secret-custom|loaded minuet provider=openai_compatible accept fn=function|provider=claude url=nil model=nil key=secret-claude-key|model=some/model key=secret-groq-key|use=off copilot=false minuet=false|use=copilot copilot=true minuet=false|no AI source called nope'
  ai-suggest 'request: Bearer test-key-123 model=test-model|on screen: 1|in the file: 1'
  up 'brew upgrade neovim|brew upgrade --cask kitty|MasonToolsUpdateSync|install rc=0'
)
# Whatever a test left behind: only its own servers, found through its own folder.
clean_up() {
  local d s
  for d in /tmp/awf.*(N/); do
    for s in outer projects default bar; do
      TMUX_TMPDIR="$d/t" tmux -L "$s" kill-server 2>/dev/null
      TMUX_TMPDIR="$d" tmux -L "$s" kill-server 2>/dev/null
    done
    pkill -f "${d:A}" 2>/dev/null
    rm -rf "$d"
  done
}

failed=0
tests=("$@")
[ $# -gt 0 ] || tests=(full app menu name bottom cli close ai ai-suggest up)
for t in "${tests[@]}"; do
  [ -f "$here/$t.sh" ] && [ -n "$expect[$t]" ] || { print -r -- "FAIL $t (no such test)"; failed=1; continue; }
  # Bounded, so a test that hangs can't stop the rest. Its servers end with it.
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
