return {
  {
    -- Images inside the terminal (kitty graphics, also through tmux). Opening a
    -- .png/.jpg/.gif/.webp shows the picture. SVGs open as editable XML; Space pi
    -- shows the rendered image in a float. Needs ImageMagick for SVG/JPG.
    "folke/snacks.nvim",
    lazy = false,
    priority = 900,
    opts = {
      image = {
        enabled = true,
        -- No "svg" here, so .svg files open as text.
        formats = { "png", "jpg", "jpeg", "gif", "bmp", "webp", "tiff", "heic", "avif", "ico", "icns" },
        doc = { enabled = true, inline = false, float = true },
      },
    },
    config = function(_, opts)
      -- Neovim runs in a project's tmux, shown inside the projects bar's tmux
      -- (tmux/projects.conf). snacks wraps image data for one tmux; wrap it once
      -- more so the outer one passes it on, when the terminal around the bar can
      -- show it (kitty's graphics protocol).
      local outer = vim.fn.system { "tmux", "-L", "projects", "list-clients", "-F", "#{client_termname}" }
      if vim.env.TMUX and (outer:match "kitty" or outer:match "ghostty") then
        vim.env.SNACKS_KITTY = "1"
        local terminal = require "snacks.image.terminal"
        terminal.write = function(data)
          data = terminal.transform and terminal.transform(data) or data
          data = "\027Ptmux;" .. data:gsub("\027", "\027\027") .. "\027\\"
          if vim.api.nvim_ui_send then
            vim.api.nvim_ui_send(data)
          else
            io.stdout:write(data)
          end
        end
      end
      require("snacks").setup(opts)
    end,
    keys = {
      {
        "<leader>pi",
        function()
          require("configs.svg_preview").preview()
        end,
        desc = "Preview this SVG / image under cursor",
      },
    },
  },

  {
    -- Live preview in the browser: SVG (including SMIL animation), HTML with CSS
    -- and JS, Markdown. SVG and Markdown update as you type; HTML on save.
    "brianhuster/live-preview.nvim",
    cmd = "LivePreview",
    keys = {
      { "<leader>pv", "<cmd>LivePreview start<cr>", desc = "Preview in browser" },
      { "<leader>pc", "<cmd>LivePreview close<cr>", desc = "Close browser preview" },
    },
  },

  -- Each nesting level of brackets in its own colour (JSON, TOML, code).
  {
    "HiPhish/rainbow-delimiters.nvim",
    event = "User FilePost",
    main = "rainbow-delimiters.setup",
    opts = {},
  },
}
