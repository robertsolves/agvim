-- AI autocomplete: suggestions as you type, from the source chosen with `agentnv ai`.
-- Copilot through copilot.lua (the free default), anything else through minuet-ai.
-- Keys live in ~/.config/agentnv/ai, readable only by you, and are never put in the
-- environment, so programs started from Neovim can't see them.
local M = {}

local function read_settings()
  local settings = {}
  local file = vim.env.AGENTNV_AI_FILE or vim.fn.expand "~/.config/agentnv/ai"
  if vim.fn.filereadable(file) == 1 then
    for _, line in ipairs(vim.fn.readfile(file)) do
      local name, value = line:match "^([%w_]+)=(.*)$"
      if name then
        settings[name] = value
      end
    end
  end
  return settings
end

local function read_providers()
  local providers = {}
  local list = vim.fn.fnamemodify(vim.fn.resolve(vim.fn.stdpath "config"), ":h") .. "/lib/ai-providers.tsv"
  if vim.fn.filereadable(list) == 1 then
    for _, line in ipairs(vim.fn.readfile(list)) do
      local id, name, kind, url, model = line:match "^([^#\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]+)"
      if id then
        providers[id] = { name = name, kind = kind, url = url, model = model }
      end
    end
  end
  return providers
end

M.settings = read_settings()
M.use = M.settings.use or "copilot"
M.provider = read_providers()[M.use]

function M.is_copilot()
  return M.use == "copilot"
end

function M.is_minuet()
  return M.use ~= "off" and M.use ~= "copilot" and M.provider ~= nil
end

local keys = { accept = "<M-l>", next = "<M-n>", prev = "<M-p>", dismiss = "<M-e>" }

function M.copilot_opts()
  return {
    panel = { enabled = false },
    filetypes = { ["*"] = true },
    -- Also while the completion menu is open, which is most of the time you're typing.
    suggestion = { enabled = true, auto_trigger = true, hide_during_completion = false, keymap = keys },
  }
end

function M.minuet_opts()
  local provider, kind = M.provider, M.provider.kind
  local name = ({ compatible = "openai_compatible", deepseek = "openai_fim_compatible" })[kind] or kind
  local options = {
    api_key = function()
      return M.settings["key_" .. M.use] or "none"
    end,
  }
  local url = M.settings["url_" .. M.use] or provider.url
  local model = M.settings["model_" .. M.use] or provider.model
  if url ~= "-" and url ~= "ask" then
    options.end_point = url
  end
  if model ~= "-" and model ~= "ask" then
    options.model = model
  end
  if kind == "compatible" then
    options.name = provider.name:match "^[^(]+"
    options.optional = { max_tokens = 256 }
  elseif kind == "deepseek" then
    options.name = "deepseek"
    options.optional = { max_tokens = 256, top_p = 0.9 }
  end
  return {
    provider = name,
    -- Asks whenever you pause. Its throttle would drop the last keystroke before a pause,
    -- and then nothing would show.
    throttle = 0,
    debounce = 300,
    provider_options = { [name] = options },
    -- Also while the completion menu is open, which is most of the time you're typing.
    virtualtext = { auto_trigger_ft = { "*" }, keymap = keys, show_on_completion_menu = true },
  }
end

-- Takes the suggestion if one is showing; says whether it did. For Tab.
function M.accept()
  if package.loaded["copilot.suggestion"] then
    local suggestion = require "copilot.suggestion"
    if suggestion.is_visible() then
      suggestion.accept()
      return true
    end
  end
  if package.loaded["minuet.virtualtext"] then
    local action = require("minuet.virtualtext").action
    if action.is_visible() then
      action.accept()
      return true
    end
  end
  return false
end

return M
