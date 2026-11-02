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
