# Bugs found in AgVim

Checked 2026-11-09 on macOS (Darwin), Neovim v0.12.6, with the repository's own tmux and zsh.
No product code was changed for this log. Line numbers are from the working tree as checked;
that tree also held uncommitted edits I did not make (`lib/project`, `lib/attention`,
`nvim/lua/configs/session.lua`, some tests), left untouched, which can move the lines cited here.

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
# lib/projects:199-208
# consoles. Sessions you made yourself in tmux keep running. The bar goes first,
# so its tabs don't start their projects again as they end.
sessions=(${(f)"$(bar list-windows -t '=projects' -F '#{window_name}' 2>/dev/null)"})
bar kill-server 2>/dev/null
for s in ${(f)"$(work list-sessions -F '#{session_name}\t#{@parent}' 2>/dev/null)"}; do
  name="${s%%$'\t'*}"
  parent="${s#*$'\t'}"
  if (( ${sessions[(Ie)$name]} )) || (( ${sessions[(Ie)$parent]} )) || [[ "$name" == Shell\ <-> ]]; then
    work kill-session -t "=$name" 2>/dev/null
  fi
done
```

The comment says the opposite: sessions you made yourself keep running. A session started
**after** AgVim opened is not a bar tab and does survive (that is what `tests/keep.sh` checks
with `scratch`), but a session that already existed is killed, with every process in it: a
build, a server, an agent, unsaved scrollback.

A second effect: `stop` runs `save-all` before killing the bar, so `.tabs/<name>/tabs` and
`.open` are written for that session. On the next `agvim`, `lib/projects:99` sees the saved
tabs and adds a tab for it again, so the killed session comes back later as a pseudo-project
named after it.

**Reproduced** on a copy of the repo with a scratch `HOME` and `TMUX_TMPDIR`: created a session
`mine`, created the bar with a window named `mine` (exactly the state startup creates), ran
`lib/projects stop --now`:

```
mine before: up
bar after: down
mine after: down
```

**Likely fix.** Make `stop` keep only what AgVim owns: a project with a file in
`saved-projects/`, a `Shell N` console, or a worktree of such a project. A session that
startup merely adopted should not match. The `add` loop can still show it as a tab; it just
must not make it AgVim's to kill.

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
# lib/project:676-679
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

## Not verified / limitations

- Item 3 was verified from the code and the tmux `pane_current_command` behaviour; the full
  `agvim send` flow (which starts a new tab) was not run end to end.
- The full suite was not run. `tests/run.sh` removes every `/tmp/awf.*` folder and kills the
  tmux servers inside them, and such folders from earlier runs were present; per `AGENTS.md`
  I did not clean up folders I did not create. Focused scratch tests were used instead. The
  bash scripts were run through `shellcheck` (clean) and every zsh script through `zsh -n`
  (clean).
