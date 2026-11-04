-- Copilot's sign-in, for `agentnv ai signin`, in the terminal rather than in Neovim's
-- screen: run with nvim --headless. Shows the code, opens the browser and waits. With
-- AGENTNV_COPILOT_STATUS set it only says whether you're signed in.
local function say(text)
  io.stdout:write(text .. "\n")
  io.stdout:flush()
end

local function finish(code)
  vim.schedule(function()
    vim.cmd((code == 0 and "qa!" or "cq " .. code))
  end)
end

require("lazy").load { plugins = { "copilot.lua" } }
local api = require "copilot.api"

vim.defer_fn(function()
  say "Timed out waiting for Copilot. Choose it again to retry."
  finish(1)
end, 900000)

-- use_client quietly does nothing until the service has started, so wait for that.
local copilot = require "copilot.client"
copilot.setup()
vim.wait(60000, function()
  return copilot.initialized or copilot.startup_error ~= nil
end, 100)
if copilot.startup_error then
  say("Copilot's service couldn't start: " .. tostring(copilot.startup_error))
  return finish(1)
end

copilot.use_client(function(client)
  coroutine.wrap(function()
    local err, status = api.check_status(client)
    if err then
      say("Copilot's service had a problem: " .. tostring(err.message or err))
      return finish(1)
    end
    if status.user and status.status ~= "NotAuthorized" and status.status ~= "NotSignedIn" then
      say("Signed in to GitHub as " .. status.user .. ".")
      return finish(0)
    end
    if vim.env.AGENTNV_COPILOT_STATUS then
      say "Not signed in to Copilot."
      return finish(3)
    end
    local start_err, signin = api.sign_in_initiate(client)
    if start_err or not signin.userCode or not signin.verificationUri then
      say("Couldn't start signing in: " .. tostring(start_err and start_err.message or "no code"))
      return finish(1)
    end
    say ""
    say("  1. Your one-time code: " .. signin.userCode .. "  (it's on your clipboard)")
    say("  2. Paste it at " .. signin.verificationUri .. " (opening it in your browser now)")
    say ""
    say "Waiting for you to finish in the browser..."
    vim.fn.system({ "pbcopy" }, signin.userCode)
    if not vim.env.AGENTNV_NO_BROWSER then
      vim.ui.open(signin.verificationUri)
    end
    local confirm_err, confirm = api.sign_in_confirm(client, { userCode = signin.userCode })
    if confirm_err or tostring(confirm.status):lower() ~= "ok" then
      say("Signing in didn't finish: " .. tostring(confirm_err and confirm_err.message or (confirm.error or {}).message))
      return finish(1)
    end
    say("Signed in to GitHub as " .. confirm.user .. ".")
    finish(0)
  end)()
end)
