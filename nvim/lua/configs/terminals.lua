-- Shells and agents open as full-screen tmux tabs of the project (the tabs along
-- the bottom), so they're saved and restored with the project's tmux session.
-- These functions are what the Space t keys call. Alt-t, Alt-. / Alt-, are tmux
-- keys (tmux.conf), so they work from any tab.
local M = {}

-- Agent CLIs on <leader>t + key, from lib/agents.tsv. Each press starts another one.
-- Claude starts connected to claudecode.nvim, so it sees your selection and shows its
-- edits as diffs (accept with <leader>aa).
-- Each starts with the flags in its fifth column ({lib}: that folder), which let
-- it mark its tab when it needs you (lib/attention).
M.agents = {}
local lib = vim.fn.fnamemodify(vim.fn.resolve(vim.fn.stdpath "config"), ":h") .. "/lib"
local list = lib .. "/agents.tsv"
if vim.fn.filereadable(list) == 1 then
  for _, line in ipairs(vim.fn.readfile(list)) do
    local fields = vim.split(line, "\t", { plain = true })
    local key, name, flags = fields[1], fields[2], fields[5]
    if key and name and key ~= "" and not key:find "^#" then
      local cmd = name
      if flags and flags ~= "" and flags ~= "-" then
        cmd = name .. " " .. flags:gsub("{lib}", function()
          return vim.fn.shellescape(lib)
        end)
      end
      table.insert(M.agents, { key = key, name = name, cmd = cmd })
    end
  end
end

-- The port of this Neovim's claudecode.nvim server, from its lock file.
local function claude_port()
  -- Where claudecode.nvim writes it: $CLAUDE_CONFIG_DIR/ide when that's set (its lockfile.lua).
  local dir = vim.env.CLAUDE_CONFIG_DIR ~= nil and vim.env.CLAUDE_CONFIG_DIR ~= "" and vim.env.CLAUDE_CONFIG_DIR .. "/ide"
    or "~/.claude/ide"
  for _, lock in ipairs(vim.fn.glob(vim.fn.expand(dir) .. "/*.lock", false, true)) do
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
  local port = name == "claude" and claude_port()
  if port then
    vim.list_extend(args, { "-e", "CLAUDE_CODE_SSE_PORT=" .. port, "-e", "ENABLE_IDE_INTEGRATION=true" })
  end
  -- When the agent exits, the tab becomes a shell: its output stays, and it's no
  -- longer an agent's tab (then_shell in lib/project). Closing the project saves
  -- which agent ran here, to start it again (lib/project).
  table.insert(args, cmd .. '; tmux set-option -wu -t "$TMUX_PANE" @agent 2>/dev/null; exec "${SHELL:-/bin/zsh}" -l')
  -- Marked as an agent's tab, for agvim send and the list of agents.
  vim.list_extend(args, { ";", "set-option", "-w", "@agent", name })
  tmux(args)
end

-- An empty box: you type the new name, not edit the old one. Empty keeps it.
function M.rename()
  local old = vim.trim(vim.fn.system { "tmux", "display-message", "-p", "#{window_name}" })
  vim.ui.input({ prompt = "Rename " .. old .. ": " }, function(name)
    if name and name ~= "" then
      tmux { "rename-window", "--", name }
      tmux { "set-option", "-w", "@named", "1" }
    end
  end)
end

-- agvim send (lib/send): text into the prompt of the agent tab you used last,
-- unsent, and that tab shown. Works for every agent.
local function send(text)
  if not vim.env.TMUX then
    vim.notify("Sending to an agent needs tmux: open it with agvim.", vim.log.levels.WARN)
    return
  end
  vim.system({ vim.fn.expand "~/.local/bin/agvim", "send" }, { stdin = text }, function(result)
    if result.code ~= 0 then
      vim.schedule(function()
        vim.notify("agvim send: " .. vim.trim(result.stderr or ""), vim.log.levels.ERROR)
      end)
    end
  end)
end

-- The file as the agent sees it: relative to the folder Neovim is in. A diff
-- view's buffer (diffview://.../path) stands for its file.
local function path_of(buf)
  local name = vim.api.nvim_buf_get_name(buf)
  name = name:gsub("^diffview://.-/%.git/[^/]+/", "")
  return vim.fn.fnamemodify(name, ":.")
end

local function block(path, first, last, lines)
  local where = first == last and (path .. ":" .. first) or (path .. ":" .. first .. "-" .. last)
  local ft = vim.bo.filetype ~= "" and vim.bo.filetype or ""
  return where .. "\n```" .. ft .. "\n" .. table.concat(lines, "\n") .. "\n```\n"
end

-- Space a>: the selection; in normal mode the change (git hunk) under the cursor,
-- with its diff, or else the line.
function M.send_selection()
  local buf = vim.api.nvim_get_current_buf()
  local path = path_of(buf)
  local mode = vim.fn.mode()
  if mode == "v" or mode == "V" or mode == "\22" then
    local a, b = vim.fn.line "v", vim.fn.line "."
    if a > b then
      a, b = b, a
    end
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "nx", false)
    send(block(path, a, b, vim.api.nvim_buf_get_lines(buf, a - 1, b, false)))
    return
  end
  local row = vim.fn.line "."
  local ok, gs = pcall(require, "gitsigns")
  if ok and gs.get_hunks then
    for _, hunk in ipairs(gs.get_hunks(buf) or {}) do
      local first = hunk.added.start
      local last = first + math.max(hunk.added.count, 1) - 1
      if row >= first and row <= last then
        local where = first == last and (path .. ":" .. first) or (path .. ":" .. first .. "-" .. last)
        send(where .. "\n```diff\n" .. table.concat(hunk.lines, "\n") .. "\n```\n")
        return
      end
    end
  end
  send(block(path, row, row, { vim.api.nvim_get_current_line() }))
end

-- Space ae: the errors and warnings on this line (the whole file's if none here).
function M.send_diagnostics()
  local buf = vim.api.nvim_get_current_buf()
  local path = path_of(buf)
  local row = vim.fn.line "." - 1
  local list = vim.diagnostic.get(buf, { lnum = row })
  if #list == 0 then
    list = vim.diagnostic.get(buf)
  end
  if #list == 0 then
    vim.notify("No errors or warnings here.", vim.log.levels.INFO)
    return
  end
  local names = { "error", "warning", "info", "hint" }
  local out = {}
  for _, d in ipairs(list) do
    table.insert(out, ("%s:%d:%d: %s: %s"):format(path, d.lnum + 1, d.col + 1, names[d.severity] or "note", d.message))
  end
  send(table.concat(out, "\n") .. "\n")
end

-- Space tR: ask the agent you used last to pick up where the last session left
-- off: /resume-session, from the skills library (agvim skills).
function M.resume_session()
  send "/resume-session"
end

-- Space tS: pick skills and slash commands for this project (agvim skills).
function M.skills()
  local agvim = vim.fn.expand "~/.local/bin/agvim"
  tmux { "display-popup", "-E", "-w", "80%", "-h", "70%", "-d", vim.fn.getcwd(), agvim .. " skills" }
end

return M
