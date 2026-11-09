# Bugs found in AgVim

Checked 2026-11-09 on macOS (Darwin), Neovim v0.12.6, with the repository's own tmux and zsh.
No product code was changed for this log. Line numbers are from commit `53fcd1d`, the
working tree being that commit plus this file's own additions.

Method: every script and config was read, then each candidate was reproduced on scratch tmux
servers with a scratch `HOME`, a scratch `TMUX_TMPDIR` and a copy of the repo, as `AGENTS.md`
requires, so the running workspace was never touched. The last section lists the candidates
that did **not** survive verification, so they are not investigated twice.

---

## 1. `agvim stop` kills tmux sessions the user made before opening AgVim — high

**What happens.** When the bar starts it adopts **every** session in the user's tmux as a tab:

```zsh
# lib/projects:93-95
for s in ${(f)"$(work list-sessions -F '#{session_name}\t#{@parent}' 2>/dev/null | awk -F'\t' '$2 == "" { print $1 }')"}; do
  add "$s"
done
```

`add` creates a bar window named after the session. `stop` then treats every bar window name as
AgVim's own and kills the matching session:

```zsh
# lib/projects:198-210
# Stop only what is AgVim's: the bar's projects and their worktrees, and
# consoles. Sessions you made yourself in tmux keep running. The bar goes first,
# so its tabs don't start their projects again as they end.
sessions=(${(f)"$(bar list-windows -t '=projects' -F '#{window_name}' 2>/dev/null)"})
bar kill-server 2>/dev/null
for s in ${(f)"$(work list-sessions -F '#{session_name}\t#{@parent}' 2>/dev/null)"}; do
  name="${s%%$'\t'*}"
  parent="${s#*$'\t'}"
  if (( ${sessions[(Ie)$name]} )) || (( ${sessions[(Ie)$parent]} )) || [[ "$name" == Shell\ <-> ]]; then
    env -u TMUX "$repo/lib/tab" end "=$name"
  fi
done
```

That filter does keep sessions started **after** AgVim opened: they never become bar tabs,
which is what `tests/keep.sh` checks with `scratch`. It does nothing for a session that
existed first: start-up made it a bar tab, so it is "the bar's" by name, and `stop` kills it
with every process in it: a build, a server, an agent, unsaved scrollback.

A second effect: `stop` runs `save-all` before killing the bar, so `.tabs/<name>/tabs` and
`.open` are written for that session. On the next `agvim`, `lib/projects:99` sees the saved
tabs and adds a tab for it again, so the killed session comes back later as a pseudo-project
named after it.

**Reproduced** on a copy of the repo at `53fcd1d`, with a scratch `HOME`, `TMUX_TMPDIR` and
stubs for `nvim` and `lazygit`: created a session `mine`, ran the bar's own start-up path
(`lib/projects`, which is what `agvim` runs), then `lib/projects stop --now`:

```
bar windows: agvim mine apprentice lead-pipeline compledo language-learning-engine
RESULT: mine KILLED
```

The other names are the copy's `saved-projects/.open` that the bar reopens; `mine` is not a
saved project -- it is a session made before the bar started, and the `add` loop turned it
into a tab.

A second name-based trigger needs no bar at all: `stop` also kills any session called
`Shell N`. With only a session `Shell 2` up and no bar server, `lib/projects stop --now`
left it down:

```
before: up
after:  down
```

**Likely fix.** Mark the bar window of a tab that start-up merely adopted (say `@adopted`)
and have `stop` skip those; or have `stop` keep only what AgVim owns: a project with a file
in `saved-projects/`, a `Shell N` console, or a worktree whose parent is such a project. The
`add` loop can still show an adopted session as a tab; it just must not make it AgVim's to
kill.

---

## 2. `agvim worktree -h` / `--help` print a branch-name error instead of help — low

`bin/agvim` routes every `worktree` argument that is not `new|list|merge|close` to
`lib/worktree new`:

```zsh
# bin/agvim:466-469
worktree | branch)
    case "$1" in
      new | list | merge | close) exec "$lib/worktree" "$@" ;;
      *) exec "$lib/worktree" new "$@" ;;
    esac
```

so `-h` becomes the proposed branch name, and the name check rejects it:

```zsh
# lib/worktree:195
git -C "$main" check-ref-format --branch "$name" >/dev/null 2>&1 || die "not a branch name git takes: $name"
```

Observed through `bin/agvim` from a scratch project (`TMUX_PANE` set, `-p` implied by it):

```
$ agvim worktree -h
agvim: not a branch name git takes: -h
$ agvim worktree --help
agvim: not a branch name git takes: --help
```

Both exit 1. No branch or worktree is created (git rejects the leading `-`), so this is a
CLI/help bug, not data damage. `agvim branch -h` is the same. Other subcommands answer `-h`
because they go through `parse` in `bin/agvim`; `worktree` bypasses it.

**Likely fix.** Handle `-h|--help` in the dispatch (`exec "$lib/worktree" --help`) or in
`lib/worktree`'s option loop, for both `worktree` and `branch`.

---

## 3. Agent tabs started with extra arguments are not marked `@agent` — medium

`lib/project tab` marks a tab as an agent's only when the command is a single word:

```zsh
# lib/project:679-682
run="$*"
[ $# -eq 1 ] && [ -n "$launch[$1]" ] && run="$launch[$1]"
win_id="$(tmux new-window -P -F '#{window_id}' -t "=$name:" -n "${1:t}" -c "..." "$run$then_shell")"
# An agent's tab is marked, for agvim send and the list of agents.
[ $# -eq 1 ] && [ -n "$launch[$1]" ] && tmux set-option -w -t "$win_id" @agent "$1"
```

`agvim tab claude --continue` — the example in `agvim help` — has `$# = 2`, so it runs
`claude --continue`, but leaves `@agent` unset. An agent tab runs through a shell
(`claude --continue; ...; exec zsh -l`), and tmux reports the pane's command as the shell:
verified with a window started as `sh -c 'sleep 60'; true`, whose
`pane_current_command` is `zsh`, not the program it runs.

Both agent consumers then drop that tab:

- `lib/send:42-44` `agents()` keeps a tab only if `#{@agent}` is set, or
  `pane_current_command` is not a shell / Neovim / lazygit. With `@agent` empty and
  `cmd=zsh`, the tab is skipped. `agvim send` (no `-t`) therefore finds no agent and
  **starts a new agent tab** instead of pasting into the existing one. `agvim send -t claude`
  still works because it also matches the window name.
- `lib/running` `rows()` uses the same test, so `agvim agents --running` omits the tab.

Dots and restore are unaffected: they use `ps`/`program_on`, and restore sets `@agent` from
`resume`.

**Likely fix.** Set `@agent` whenever the first command word names an agent, independently of
argument count: `[ -n "$launch[$1]" ] && tmux set-option -w -t "$win_id" @agent "$1"`. Only
the `$# -eq 1` guard is wrong; `$1` is still `claude` after the shift.

---

## 4. `agvim roots remove` of the last root leaves a newline and a blank line — low

```zsh
# bin/agvim:546-547
updated="$(grep -vxF -- "$where" "$roots_file")"
print -r -- "$updated" >"$roots_file"
```

With one root left, `updated` is empty, and `print -r -- ""` writes one newline instead of
truncating the file. Verified with a scratch `HOME` holding only the four defaults and
removing each in turn:

```
file:         0000000 \n
roots output: 0000000 \n
```

`agvim roots` therefore prints a blank line instead of nothing. The picker ignores it (the
`(N/)` filter in `lib/p`), so the impact is cosmetic, but the file no longer means "no roots".

**Likely fix.** Truncate when the result is empty, e.g.
`[ -n "$updated" ] && print -r -- "$updated" >"$roots_file" || : >"$roots_file"`.

---

## 5. `Space c-` inserts a `//` separator into every kind of file — low

`nvim/lua/configs/add_comment_separator.lua` hardcodes the line and never looks at the
buffer's filetype or `commentstring`:

```lua
-- nvim/lua/configs/add_comment_separator.lua:5-8
M.add_comment_separator = function()
  local a = "// -----------------------------------------------------------------------------"
  vim.api.nvim_put({ a }, "l", true, true)
end
```

`nvim/lua/mappings.lua:15-17` maps it to `<Leader>c-` in normal mode with no filetype
condition, and `nvim/README.md:51` advertises it as "insert a comment separator line".
In Python, shell, Lua, Ruby, YAML, TOML or Markdown it inserts JavaScript comment syntax:
a syntax error in the first four, and wrong in the rest.

**Reproduced** headless with the module itself (Python buffer):

```
$ nvim --headless --noplugin -u NONE -n \
    -c 'lua package.path = "nvim/lua/?.lua;" .. package.path' \
    -c 'setfiletype python' \
    -c 'lua vim.api.nvim_buf_set_lines(0,0,-1,false,{"# existing"})' \
    -c 'lua require("configs.add_comment_separator").add_comment_separator()' \
    -c 'lua vim.fn.writefile(vim.api.nvim_buf_get_lines(0,0,-1,false), "/tmp/out")' \
    -c 'qa!'
# existing
// -----------------------------------------------------------------------------
```

**Likely fix.** Build the line from `vim.bo.commentstring`
(`commentstring:gsub("%%s", string.rep("-", 77))`, which gives `-- ---…` for Lua,
`# ---…` for Python/shell, `<!-- ---… -->` for HTML), or pick the leader by filetype.

---

## 6. A lock that was never acquired is still deleted on exit — low

Both lock helpers wait for their lock directory, then carry on whether or not they got
it, and both remove the lock unconditionally afterwards:

```zsh
# lib/colours:35-37 (next)
lock="${TMUX_TMPDIR:-/tmp}/agvim-colour-$UID.lock"
for _ in {1..40}; do mkdir "$lock" 2>/dev/null && break; sleep .05; done
trap 'rmdir "$lock" 2>/dev/null' EXIT
```

```zsh
# lib/project:172-176 (save)
local lock="$store/.tabs/.$1.lock" i
mkdir -p "$store/.tabs"
for i in {1..50}; do mkdir "$lock" 2>/dev/null && break; sleep 0.1; done # a stale lock goes after 5 s
save_now "$@"
rmdir "$lock" 2>/dev/null
```

A process that never created the directory still deletes it when it finishes, so the
mutual exclusion the lock exists for is broken for everyone after it. In `save` the
comment also promises that "a stale lock goes after 5 s", but nothing there removes one
(`save_soon` does, at `lib/project:286-287`); a lock left by a killed save makes the next
save wait the whole 5 s and then delete it. In `colours next` the same timeout makes two
windows created together run at once, which can give them the same colour.

**Reproduced** for `colours next` on a scratch tmux server, with a lock already there
(from the process that "holds" it):

```
$ mkdir "$TMUX_TMPDIR/agvim-colour-$UID.lock"
$ lib/colours next work %0
rc=0 waited=3s
lock: DELETED by the run that never got it
colour @colour=4 @fg=default
```

So the run that lost the race (a) delayed that tab's colour by 2-3 s, (b) coloured it
without the lock, and (c) removed the holder's lock, letting a third run in too.

**Likely fix.** Remember whether `mkdir` succeeded (`got=1`), arm the trap/`rmdir` only
then, and on timeout clear the lock as stale and retry once, the way `save_soon` does.

---

## 7. Closing a worktree silently deletes edited ignored files — medium

`close()` in `lib/worktree` decides whether to warn with plain `git status --porcelain`,
which leaves out ignored files:

```zsh
# lib/worktree, close()
local dirty="" keep=""
[ -n "$(git -C "$dir" status --porcelain 2>/dev/null)" ] && dirty=1
if [ -n "$dirty" ] && [[ "$force" != yes* ]]; then
  ...
  print -rn -- "Throw them away and close it? (y/N) "
```

Every new worktree gets the repo's `.worktreeinclude` files (`copy_included`: `.env` and the
like), and those are normally gitignored, so they never appear in `status --porcelain`. A
worktree whose only change is an edited `.env` therefore looks clean: no question, then
`git worktree remove --force` deletes it. The same status feeds the `files` count in `stat`
(the "from main · 4 files" text) and the immediate close a click does, so the row shows no
change either. The included file is a copy of the repo's, so its *content* may be replaced
along the way; edits made in the worktree are what is lost.

**Reproduced** on a copy of the repo, scratch `HOME`/`TMUX_TMPDIR`, a project `p1` with a
worktree `w1` on a branch with no commits of its own (so `merged` is true), `.env` gitignored
and edited inside the worktree:

```
status lines: 0
Closed wt1.
rc=0
RESULT: .env DELETED silently
```

The control, with one tracked file modified, stops as it should:

```
rc=2
RESULT: control worktree KEPT
```

**Likely fix.** Count ignored files the repo's copy doesn't have (or whose content differs)
as work that would go: `git status --porcelain --ignored=matching` and skip the `!!` entries
that `copy_included` would copy unchanged.

---

## 8. `agvim send` (and Neovim `Space a>`) can paste into any non-shell program — medium

`send` says it goes "to the agent tab you used last". Its idea of an agent tab is any
window whose foreground program is not a shell, Neovim or lazygit:

```zsh
# lib/send:42-45
agents() {
  tmux list-windows -t "$session" -F '#{window_id}\t#{@agent}\t#{window_name}\t#{pane_current_command}' |
    awk -F'\t' '$2 != "" || $4 !~ /^-?(zsh|bash|fish|sh|nvim|lazygit)$/ { print }'
}
```

`lib/attention`'s `sync` (tmux's `session-window-changed`/`client-session-changed`
hooks) records the session's current window as `@last-agent` under the same rule, and
`send` prefers that window (`lib/send:52-56`). So a pager, `ssh`, `htop`, `psql`, a
`git`/`docker` command, `less` — every program that isn't in the list — becomes the
"last agent used". `send` then pastes the text and shows that window
(`lib/send:84-85`), which is how it is meant to leave you one Enter away: in an `ssh`
tab, that Enter runs the text as a command on the remote host.

The check exists and is right (`fg_kind` in `lib/attention`, with `agents.tsv` names,
`node`/`python` wrappers and the `ui` list), and `bell` uses it; `agents()` and `sync`
do not.

**Reproduced** on a scratch server: a session `proj` with `shell 1` and a window named
`git log` whose foreground program was `cat` (standing in for a pager), current window
`git log`:

```
windows: @0=tmux[zsh] @1=git log[cat]
last-agent after sync: @1
send rc=0
--- what the 'agent' pane shows ---
git rebase --abort
--- selected window: git log
```

**Likely fix.** Use `@agent` plus the `agents.tsv` names and their `node`/`python`
wrappers (the `fg_kind` rule) for `agents()` and for `@last-agent`, so only a real
agent can be the target.

---

## 9. Closing a folder tab whose path has an apostrophe doesn't take the folder out — low

When the tab belongs to one of a project's other folders (`@folder_tab`), the `x` on it
asks, then runs two commands: `_tab end` closes the tab, `_project remove` takes the
folder out. Both are written into one `confirm-before` as shell text:

```zsh
# lib/tab:84-86
    tmux confirm-before -b -t "$1" -p "Close ${name//\#/##} and take it out of ${project//\#/##}? (y/n)" \
      "run-shell -b \"~/.local/bin/agvim _tab end '$2' >/dev/null 2>&1 ; true\" ; run-shell -b \"~/.local/bin/agvim _project remove '${project//\'/}' '${folder//\'/\'\\\\\'\'}' >/dev/null 2>&1 ; true\""
```

The folder is put between single quotes, but `${folder//\'/…}` escapes an apostrophe
with backslashes, which mean nothing inside single quotes: the quote ends there and the
closing one is missing, so the whole command is a shell syntax error.

**Reproduced** with a folder `.../code/it's here` (a stub `tmux` answering the `display`
queries, then the generated command run through `sh`):

```
confirm: ... _project remove 'P' '/tmp/awf-q.XQMl3E/code/it\'\\'\'s here' >/dev/null 2>&1 ; true"
  args passed:
  error: sh: -c: line 0: unexpected EOF while looking for matching `'' sh: -c: line 1: syntax error: unexpected end of file
```

The tab-closing half is a separate `run-shell`, so it still runs; the remove never does.
Run by a real tmux (`run-shell -b`, as the binding does) with a stub `agvim` logging its
arguments:

```
== what the run-shell commands did ==
agvim _tab end %1
== remove reached: 0 ==
```

The same probe with `/tmp/.../code/ok` and `/tmp/.../code/it s here` passes the path
through unchanged, so it is the apostrophe alone.

What's left: the tab closes and the folder stays in `saved-projects/<project>`. `agvim
list` still shows it as one of the project's folders, `agvim remove` still has to be
used to take it out, and a start with no saved tabs for that project opens a folder tab
for it again (`lib/project:337-339`).

Project names aren't affected: `clean()` (`lib/project:81-87`) turns anything outside
`[[:alnum:] _-]` into `_`, so `${project//\'/}` never has a quote to remove.

**Likely fix.** Keep the path out of the prompt command: pass the tab's window (`$2`) to
`lib/project` and have it read `@folder` and `#{session_name}` itself before the tab is
killed, as it already does for restores (`lib/project:261-263`). Or quote it with zsh's
`${(q)folder}`.

---

## Checked and not bugs

These were suspected while reading and disproved, so they don't need another look:

- `lib/colours theme`'s `[[ $hex =~ '^#[0-9a-fA-F]{6}$' ]]`: a quoted regex **does** work in
  this zsh (5.9); tested directly.
- Tab separators throughout `lib/` are real tab bytes, not `\t`; `od -c` and `grep` for a
  literal backslash-t confirmed it. `lib/attention`'s `sync` uses `(@s:<TAB>:)` and keeps
  empty fields.
- `lib/colours next`'s fallback index is not 0 on a new window: the new window itself
  contributes an empty `#{@colour}` field, so `used` has one element. A scratch sequence gave
  4, 2, 5, as intended.
- `tmux set-option -t <window-id>` is session-scoped here, which is what `save_now`'s
  `@restoring` check reads. `list-sessions -F '#{window_id}'` resolves to the session's
  current window, which is what `lib/attention sync` wants for `@last-agent`.
- `:restart! source <file>` is valid in Neovim 0.12 (`:restart[!] [+cmd] [command]`), so
  `nvim/lua/configs/refresh.lua` is correct.
- `minuet-ai.nvim` accepts the provider names used (`openai`, `claude`, `codestral`, `gemini`,
  `openai_fim_compatible`), and every server name in `nvim/lua/configs/lspconfig.lua`
  (`sourcekit`, `kotlin_lsp`, `slint_lsp`, `wgsl_analyzer`, …) has a config file in the
  installed nvim-lspconfig.
- `lib/send`'s `case` for `-t|-p` uses zsh's `;|`, which re-tests the next pattern; `-p` does
  reach the `-p)` branch (tested).
- `lib/p --rows` keeps `AW_CURRENT`: it is exported before fzf starts, so fzf's reload command
  inherits it.
- `lib/project refresh`'s `count` survives its pipeline (zsh runs the last part in the current
  shell); tested.
- `tests/agents.sh` being non-executable is harmless: `tests/run.sh` invokes
  `/bin/zsh "$here/$t.sh"`.
- `nvim/lua/configs/terminals.lua`'s `new-window ... ; set-option -w @agent` does mark the new
  window (tested on a scratch server), so the Neovim `Space tc` path is fine.
- `lib/attention` does implement `session` (line 227), matching `lib/claude-settings.json`'s
  `SessionStart` hook.
- `nvim/lua/configs/lazy.lua` listing `"ftplugin"` in `performance.rtp.disabled_plugins`
  does nothing, and does no harm: lazy only filters files in a plugin's `plugin/` and
  `after/plugin/` directories by basename (`lazy/core/loader.lua:449-452`), so
  `$VIMRUNTIME/ftplugin` is untouched and `commentstring` still comes from it (checked
  for lua, python and sh).
- `:ClaudeCode --resume` and `--continue` do pass their arguments: the command is
  `nargs="*"` and `terminal.simple_toggle` appends them to the `claude` command string
  (`claudecode.nvim/lua/claudecode/terminal.lua:345-357`), so `claude --resume` runs.
- `nvim-dap` adapter functions take `(callback, config)` (`dap.lua:245`), which matches
  `configs/dap.lua`'s Swift adapter, so its argument order is right.
- `Snacks.image.buf.attach(buf, { src = ... })` is supported (`snacks/image/buf.lua:43`)
  and `Snacks.image.hover()` exists (`snacks/image/init.lua:223`), so `Space pi`'s two
  paths are wired correctly.
- `nvim/lua/plugins/preview.lua`'s extra tmux wrap is correct: snacks already transforms
  for the project's tmux when `$TMUX` is set, and the second wrap is the layer the bar's
  server unwraps, so the kitty payload arrives intact two tmux deep.
- Every tmux `run-shell`/`run` binding and hook was checked for the view-mode trap in
  AGENTS.md (output or a non-zero exit swallowing keys): all 22 in `tmux/tmux.conf` and
  `tmux/projects.conf` use `-b` and `>/dev/null 2>&1; true`, and the click bindings that
  ask use `confirm-before -b` or `if -F`.
- `lib/tab`'s `finish` only kills `procs_of` the targets' own panes (plus orphans whose
  `TMUX_PANE` and `TMUX` server match), never a pattern of process names.
- `lib/colours theme`'s `[[ "$hex" =~ '^#[0-9a-fA-F]{6}$' ]]` looked like zsh's literal
  (quoted) form, which would have skipped every colour: it isn't. `zsh -c` matched
  `#ffffff` and `#FFFFFF` for that exact expression, so tabs do follow the theme.
- The read-only `bin/agvim` commands were run with a scratch `HOME`: `help`, `agents`,
  `ai list`, `roots`, `terminal` and `version` all behaved, and `agvim` with no terminal
  printed its help instead of asking.
- The bar's `+ Worktree` and `Merge` pass `#{q:window_name}` as the first argument, which is
  what `new-here` and `merge-here` expect (`new "$args[1]" ...`), so their argument order is
  right.
- `bin/agvim tab` does take a trailing `-p <name>`: the last-two-arguments check strips it
  before the command is run (it just isn't aware of an earlier `--`, which no documented
  use hits).

## Not verified / limitations

- Item 3 was verified from the code and the tmux `pane_current_command` behaviour; the full
  `agvim send` flow (which starts a new tab) was not run end to end.
- Item 6's `lib/project save` side is the same code pattern, read rather than run (the
  end-to-end reproduction covers `lib/colours next`).
- Item 7 was reproduced by running `lib/worktree close` with a scratch saved project and
  worktree and no bar server; the same decision reached from a mouse click on the row was
  not driven.
- Item 8 was reproduced with a scratch tmux session and a window running `cat` in place of
  a real pager or `ssh`; the paste itself and the window switch are the product's, the
  consequences in those programs were reasoned, not run.
- Item 9 was reproduced with a stub `tmux` for the `display`/`confirm-before` answers, the
  generated command through `sh` and through a real tmux `run-shell -b`, with a stub
  `agvim` logging its arguments. Clicking the tab's `x` with a real client was not driven.
- The full suite was not run. `tests/run.sh` removes every `/tmp/awf.*` folder and kills the
  tmux servers inside them, and such folders from earlier runs were present; per `AGENTS.md`
  I did not clean up folders I did not create. Focused scratch tests were used instead. The
  bash scripts were run through `shellcheck` (clean) and every zsh script through `zsh -n`
  (clean).
