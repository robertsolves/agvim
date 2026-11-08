#!/bin/zsh
# agvim ai on a scratch HOME, then the real Neovim config reading those settings.
src="${0:A:h:h}"
real_home="$HOME"
base=$(mktemp -d /tmp/awf.XXXX); base=${base:A}
export HOME=$base/home TMUX_TMPDIR=$base/t; mkdir -p $HOME/.local/bin $TMUX_TMPDIR; unset TMUX
export AGVIM_REAL_TMUX="$(command -v tmux)"; mkdir -p $HOME/stubs; cp "$src/tests/tmux-guard" $HOME/stubs/tmux; export PATH="$HOME/stubs:$PATH" # only this test's own servers, also if its folder goes
ln -s $src/bin/agvim ~/.local/bin/agvim
a() { print -r -- "\$ agvim $*"; agvim "$@" 2>&1; local rc=$?; [ $rc = 0 ] || print -r -- "  rc=$rc"; }
export PATH="$HOME/.local/bin:$PATH"
a ai </dev/null
a ai list </dev/null | head -4
print -r -- "secret-claude-key" | a ai claude --no-check
print -r -- "secret-groq-key" | a ai groq --no-check
print -r -- "secret-groq-key" | a ai groq --model some/model --no-check
print -r -- "secret-custom" | a ai custom --url http://localhost:9/v1/chat/completions --model m1 --no-check
a ai nope </dev/null
a ai </dev/null
a ai list </dev/null | grep -E 'claude|custom|deepseek'
print -r -- "mode $(stat -f %Lp ~/.config/agvim/ai)"
print -r -- "key on screen: $( { agvim ai list; agvim ai; } </dev/null 2>&1 | grep -c secret)"
print -r -- "=== Neovim reads it"
cat > $base/check.lua <<'LUA'
local ai = require "configs.ai"
local out = { "use=" .. ai.use .. " copilot=" .. tostring(ai.is_copilot()) .. " minuet=" .. tostring(ai.is_minuet()) }
if ai.is_minuet() then
  local o = ai.minuet_opts()
  local p = o.provider_options[o.provider]
  out[#out + 1] = "provider=" .. o.provider .. " url=" .. tostring(p.end_point) .. " model=" .. tostring(p.model) .. " key=" .. p.api_key()
  require("lazy").load { plugins = { "minuet-ai.nvim" } }
  out[#out + 1] = "loaded minuet provider=" .. require("minuet").config.provider .. " accept fn=" .. type(require("minuet.virtualtext").action.is_visible)
end
vim.fn.writefile(out, vim.env.AGVIM_AI_OUT)
vim.cmd "qa!"
LUA
n() { ( export HOME="$real_home" AGVIM_AI_FILE="$base/home/.config/agvim/ai" AGVIM_AI_OUT=$base/out; nvim --headless -c "luafile $base/check.lua" >/dev/null 2>&1; cat $base/out ); }
n
agvim ai claude --no-check </dev/null >/dev/null 2>&1; n
agvim ai groq --no-check </dev/null >/dev/null 2>&1; n
agvim ai off </dev/null >/dev/null; n
agvim ai copilot </dev/null >/dev/null; n
