-- Debug adapters. Dart/Flutter comes from flutter-tools and Rust from rustaceanvim;
-- this file adds Swift, Python and JS/TS, and the shared UI.
-- F5 also offers the configurations in the project's .vscode/launch.json.
local dap, dapui = require "dap", require "dapui"

dapui.setup()
require("nvim-dap-virtual-text").setup {}

dap.listeners.before.attach.dapui_config = function()
  dapui.open()
end
dap.listeners.before.launch.dapui_config = function()
  dapui.open()
end
dap.listeners.before.event_terminated.dapui_config = function()
  dapui.close()
end
dap.listeners.before.event_exited.dapui_config = function()
  dapui.close()
end

vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DiagnosticError" })
vim.fn.sign_define("DapBreakpointCondition", { text = "◆", texthl = "DiagnosticError" })
vim.fn.sign_define("DapLogPoint", { text = "◉", texthl = "DiagnosticInfo" })
vim.fn.sign_define("DapBreakpointRejected", { text = "○", texthl = "DiagnosticHint" })
vim.fn.sign_define("DapStopped", { text = "▶", texthl = "DiagnosticWarn", linehl = "Visual" })

--------------------------------------------------------------------------------
-- Python: debugpy from Mason; the program runs in the project's .venv if found.
--------------------------------------------------------------------------------

require("dap-python").setup(vim.fn.stdpath "data" .. "/mason/packages/debugpy/venv/bin/python")

--------------------------------------------------------------------------------
-- JavaScript / TypeScript: js-debug from Mason. Node 22.18+ runs .ts directly.
--------------------------------------------------------------------------------

dap.adapters["pwa-node"] = {
  type = "server",
  host = "localhost",
  port = "${port}",
  executable = { command = "js-debug-adapter", args = { "${port}" } },
}

for _, ft in ipairs { "javascript", "typescript" } do
  dap.configurations[ft] = {
    {
      type = "pwa-node",
      request = "launch",
      name = "Launch current file",
      program = "${file}",
      cwd = "${workspaceFolder}",
    },
    {
      type = "pwa-node",
      request = "attach",
      name = "Attach to process",
      processId = require("dap.utils").pick_process,
      cwd = "${workspaceFolder}",
    },
  }
end

--------------------------------------------------------------------------------
-- Swift (SwiftPM): builds the product with `swift build`, then debugs it with
-- Xcode's lldb-dap. Also runs the VS Code "swift" configs in .vscode/launch.json,
-- which name a `target` and `configuration` instead of a program path.
--------------------------------------------------------------------------------

local lldb_dap = vim.trim(vim.fn.system { "xcrun", "-f", "lldb-dap" })
dap.adapters.lldb = { type = "executable", command = lldb_dap, name = "lldb" }

dap.adapters.swift = function(callback, config)
  local cwd = vim.fn.getcwd()
  local product = config.target or vim.fn.fnamemodify(cwd, ":t")
  local build_config = config.configuration or "debug"
  vim.notify("swift build -c " .. build_config .. " --product " .. product)
  vim.system(
    { "swift", "build", "-c", build_config, "--product", product },
    { cwd = cwd, text = true },
    vim.schedule_wrap(function(result)
      if result.code ~= 0 then
        vim.notify(result.stdout .. result.stderr, vim.log.levels.ERROR)
        return
      end
      callback(vim.tbl_extend("force", dap.adapters.lldb, {
        enrich_config = function(launch, on_config)
          launch = vim.deepcopy(launch)
          launch.program = cwd .. "/.build/" .. build_config .. "/" .. product
          launch.cwd = cwd
          launch.target, launch.configuration, launch.preLaunchTask = nil, nil, nil
          on_config(launch)
        end,
      }))
    end)
  )
end

dap.configurations.swift = {
  { type = "swift", request = "launch", name = "Build and debug (SwiftPM, folder name)", args = {} },
}
