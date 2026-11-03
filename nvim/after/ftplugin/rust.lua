local function rust(lhs, cmd, desc)
  vim.keymap.set("n", lhs, "<cmd>RustLsp " .. cmd .. "<CR>", { buffer = true, desc = desc })
end

rust("<Leader>dt", "testables", "Show testables")
rust("<Leader>Rr", "runnables", "Rust: runnables")
rust("<Leader>Rd", "debuggables", "Rust: debug")
rust("<Leader>Re", "explainError", "Rust: explain error")
rust("<Leader>Rm", "expandMacro", "Rust: expand macro")
rust("<Leader>Rc", "openCargo", "Rust: open Cargo.toml")
