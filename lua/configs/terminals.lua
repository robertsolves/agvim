-- A VS Code-style panel along the bottom, in the project folder Neovim was
-- opened in. Each entry is its own terminal that toggles open/closed and keeps
-- running while hidden.
local M = {}

-- Agent CLIs on <leader>t + key. Claude is launched connected to claudecode.nvim,
-- so it sees your selection and shows its edits as diffs (accept with <leader>aa).
M.agents = {
  { key = "c", name = "claude", cmd = "claude" },
  { key = "x", name = "codex", cmd = "codex" },
  { key = "o", name = "opencode", cmd = "opencode" },
  { key = "k", name = "kilo", cmd = "kilo" },
  { key = "g", name = "gemini", cmd = "gemini" },
}

local function ide_env(name)
  local ok, claudecode = pcall(require, "claudecode")
  if name ~= "claude" or not ok or not claudecode.state.port then
    return nil
  end
  return {
    ENABLE_IDE_INTEGRATION = "true",
    FORCE_CODE_TERMINAL = "true",
    CLAUDE_CODE_SSE_PORT = tostring(claudecode.state.port),
  }
end

-- Toggles the bottom terminal called `id`, running `cmd` the first time.
function M.toggle(id, cmd)
  require("nvchad.term").toggle {
    pos = "bo sp",
    id = id,
    size = 0.35,
    cmd = cmd,
    termopen_opts = { env = ide_env(id) },
  }
end

return M
