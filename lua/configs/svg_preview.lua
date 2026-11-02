-- Renders the current SVG buffer (unsaved edits included) to a PNG and shows it
-- in a float. Animated SMIL shows its first frame; use <leader>pv for the
-- animated version in the browser.
local M = {}

function M.preview()
  if vim.bo.filetype ~= "svg" then
    return Snacks.image.hover()
  end

  local base = vim.fn.tempname()
  vim.fn.writefile(vim.api.nvim_buf_get_lines(0, 0, -1, false), base .. ".svg")
  local result = vim
    .system({ "rsvg-convert", "--width", "1000", "--keep-aspect-ratio", "-o", base .. ".png", base .. ".svg" })
    :wait()
  if result.code ~= 0 then
    vim.notify("rsvg-convert: " .. result.stderr, vim.log.levels.ERROR)
    return
  end

  local width = math.floor(vim.o.columns * 0.5)
  local height = math.floor(vim.o.lines * 0.6)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    border = "rounded",
    title = " " .. vim.fn.expand "%:t" .. " ",
  })
  Snacks.image.buf.attach(buf, { src = base .. ".png" })
  vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buf, desc = "Close preview" })
  vim.keymap.set("n", "<Esc>", "<cmd>close<cr>", { buffer = buf, desc = "Close preview" })
end

return M
