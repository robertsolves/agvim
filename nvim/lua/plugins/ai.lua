local ai = require "configs.ai"

return {
  -- Suggestions as you type: Tab or Alt-l accepts, Alt-n / Alt-p next / previous, Alt-e
  -- dismisses. Choose the source with `agvim ai`.
  {
    "zbirenbaum/copilot.lua",
    cond = ai.is_copilot(),
    cmd = "Copilot",
    event = "InsertEnter",
    opts = ai.copilot_opts,
  },

  {
    "milanglacier/minuet-ai.nvim",
    cond = ai.is_minuet(),
    -- Before the file loads: it turns itself on for a buffer when its filetype is set.
    event = { "BufReadPre", "BufNewFile" },
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = function()
      return ai.minuet_opts()
    end,
  },

  -- Tab: an item you've moved to in the completion menu, else the AI suggestion, else
  -- on through the menu, else what it did before.
  {
    "hrsh7th/nvim-cmp",
    opts = function(_, opts)
      local cmp = require "cmp"
      opts.mapping = opts.mapping or {}
      opts.mapping["<Tab>"] = cmp.mapping(function(fallback)
        if not cmp.get_active_entry() and ai.accept() then
          cmp.close()
        elseif cmp.visible() then
          cmp.select_next_item()
        elseif require("luasnip").expand_or_jumpable() then
          require("luasnip").expand_or_jump()
        else
          fallback()
        end
      end, { "i", "s" })
      return opts
    end,
  },
}
