return {
  {
    -- Claude Code's IDE integration (same protocol as the VS Code extension):
    -- Claude sees your selection and open file, and shows its edits as diffs here.
    -- <leader>tc runs Claude in the bottom panel already connected; <leader>ac opens
    -- it on the right instead. In another tmux pane, run `claude` then /ide.
    "coder/claudecode.nvim",
    lazy = false,
    opts = {
      terminal = { provider = "native", split_side = "right", split_width_percentage = 0.4 },
    },
    keys = {
      { "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "Claude: toggle" },
      { "<leader>af", "<cmd>ClaudeCodeFocus<cr>", desc = "Claude: focus" },
      { "<leader>ar", "<cmd>ClaudeCode --resume<cr>", desc = "Claude: resume" },
      { "<leader>aC", "<cmd>ClaudeCode --continue<cr>", desc = "Claude: continue" },
      { "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", desc = "Claude: add file" },
      { "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Claude: send selection" },
      { "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Claude: accept diff" },
      { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Claude: reject diff" },
    },
  },
}
