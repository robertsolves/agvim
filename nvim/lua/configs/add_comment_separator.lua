-- ~/.config/nvim/configs/add_comment_separator.lua

local M = {}

local width = 80

-- A line of dashes in the buffer's own comment syntax ('commentstring'): "# ---" in
-- Python or shell, "-- ---" in Lua, "<!-- --- -->" in HTML. "//" when it has none.
M.add_comment_separator = function()
  local cs = vim.bo.commentstring
  if cs == nil or not cs:find("%%s") then
    cs = "// %s"
  end
  local before, after = cs:match("^(.-)%%s(.-)$")
  before = before:gsub("%s*$", "") .. " "
  after = after:gsub("^%s*", "")
  if after ~= "" then
    after = " " .. after
  end
  local dashes = math.max(3, width - vim.fn.strdisplaywidth(before .. after))
  vim.api.nvim_put({ before .. string.rep("-", dashes) .. after }, "l", true, true)
end

return M
