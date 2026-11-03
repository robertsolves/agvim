-- Open the live UI preview for the component under the cursor.
vim.keymap.set("n", "<Leader>sp", function()
  vim.lsp.buf.code_action {
    filter = function(action)
      return action.title:lower():find "preview" ~= nil
    end,
    apply = true,
  }
end, { buffer = true, desc = "Slint: live preview" })
