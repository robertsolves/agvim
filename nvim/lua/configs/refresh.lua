-- agvim refresh restarts each running Neovim with the same files and splits
-- (lib/project). A terminal inside Neovim (Claude on Space ac, a :terminal) would
-- end with the restart, so a Neovim with one running is left alone and says why.
local M = {}

local function running_terminals()
  local n = 0
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[buf].buftype == "terminal" then
      local job = vim.b[buf].terminal_job_id
      if job and vim.fn.jobwait({ job }, 0)[1] == -1 then
        n = n + 1
      end
    end
  end
  return n
end

function M.restart(file)
  if running_terminals() > 0 then
    vim.notify(
      "agvim refresh: not restarted, a terminal is running in this Neovim. :restart when it's done.",
      vim.log.levels.WARN
    )
    return
  end
  vim.cmd "silent! wall"
  vim.opt.sessionoptions:remove { "terminal", "blank" }
  vim.cmd("mksession! " .. vim.fn.fnameescape(file))
  vim.cmd("restart source " .. vim.fn.fnameescape(file))
end

vim.api.nvim_create_user_command("AgvimRefresh", function(opts)
  M.restart(opts.args)
end, { nargs = 1, complete = "file", desc = "agvim refresh: restart with the same files and splits" })

return M
