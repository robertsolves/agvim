-- ~/.config/nvim/configs/add_comment_separator.lua

local M = {}

M.add_comment_separator = function()
  local a = "// -----------------------------------------------------------------------------"
  vim.api.nvim_put({ a }, "l", true, true)
end

return M
