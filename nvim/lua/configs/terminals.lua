-- Shells and agents open as full-screen tmux tabs of the project (the tabs along
-- the bottom), so they're saved and restored with the project's tmux session.
-- These functions are what the Space t keys call. Alt-t, Alt-. / Alt-, are tmux
-- keys (tmux.conf), so they work from any tab.
local M = {}

-- Agent CLIs on <leader>t + key, from lib/agents.tsv. Each press starts another one.
-- Claude starts connected to claudecode.nvim, so it sees your selection and shows its
-- edits as diffs (accept with <leader>aa).
M.agents = {}
local list = vim.fn.fnamemodify(vim.fn.resolve(vim.fn.stdpath "config"), ":h") .. "/lib/agents.tsv"
if vim.fn.filereadable(list) == 1 then
  for _, line in ipairs(vim.fn.readfile(list)) do
    local key, name = line:match "^([^#\t]+)\t([^\t]+)"
    if key then
      table.insert(M.agents, { key = key, name = name, cmd = name })
    end
  end
end

-- The port of this Neovim's claudecode.nvim server, from its lock file.
local function claude_port()
  for _, lock in ipairs(vim.fn.glob(vim.fn.expand "~/.claude/ide/*.lock", false, true)) do
    local ok, data = pcall(vim.json.decode, table.concat(vim.fn.readfile(lock), "\n"))
    if ok and data.pid == vim.fn.getpid() then
      return vim.fn.fnamemodify(lock, ":t:r")
    end
  end
end

local function run(cmd)
  if not vim.env.TMUX then
    vim.notify("Terminal tabs need tmux: open it with agvim.", vim.log.levels.WARN)
    return
  end
  vim.system(cmd, {}, function(result)
    if result.code ~= 0 then
      vim.schedule(function()
        vim.notify(vim.fn.fnamemodify(cmd[1], ":t") .. " failed: " .. (result.stderr or ""), vim.log.levels.ERROR)
      end)
    end
  end)
end

local function tmux(args)
  run(vim.list_extend({ "tmux" }, args))
end

-- A new full-screen tab in the project folder: a shell ("shell N", lib/tab)
-- when `cmd` is nil, else the agent `cmd` in a tab called `name`.
function M.new(name, cmd)
  if not cmd then
    run { vim.fn.expand "~/.local/bin/agvim", "_tab", "new" }
    return
  end
  local args = { "new-window", "-c", vim.fn.getcwd(), "-n", name }
  local port = cmd == "claude" and claude_port()
  if port then
    vim.list_extend(args, { "-e", "CLAUDE_CODE_SSE_PORT=" .. port, "-e", "ENABLE_IDE_INTEGRATION=true" })
  end
  -- "; true" keeps the tab open as a shell when the agent exits. Closing the
  -- project saves which agent ran here, to start it again (lib/project).
  table.insert(args, cmd .. "; true")
  tmux(args)
end

function M.rename()
  tmux { "command-prompt", "-I", "#{window_name}", "-p", "Name:", "rename-window '%%' ; set-option -w @named 1" }
end

return M
