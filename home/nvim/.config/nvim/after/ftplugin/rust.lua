-- ~/.config/nvim/after/ftplugin/rust.lua
-- Rust-only keymaps. These use rustaceanvim's :RustLsp commands, which are
-- richer than the generic LSP equivalents (grouped code actions, hover
-- actions, runnables/debuggables, macro expansion, etc).

local bufnr = vim.api.nvim_get_current_buf()
local function m(keys, fn, desc)
  vim.keymap.set("n", keys, fn, { buffer = bufnr, desc = desc, silent = true })
end

-- Code actions WITH rust-analyzer's grouping (better than vim.lsp.buf.code_action)
m("<leader>ca", function() vim.cmd.RustLsp("codeAction") end, "Rust code action")

-- Hover actions (override the generic K from the LspAttach autocmd)
m("K", function() vim.cmd.RustLsp({ "hover", "actions" }) end, "Rust hover actions")

-- Explain the error under the cursor (rust-analyzer's --explain)
m("<leader>re", function() vim.cmd.RustLsp("explainError") end, "Explain error")

-- Render diagnostic as a rustc-style message
m("<leader>rd", function() vim.cmd.RustLsp("renderDiagnostic") end, "Render diagnostic")

-- Runnables / testables / debuggables (pick from a menu; bang reruns the last)
m("<leader>rr", function() vim.cmd.RustLsp("runnables") end, "Runnables")
m("<leader>rt", function() vim.cmd.RustLsp("testables") end, "Testables")
m("<leader>rD", function() vim.cmd.RustLsp("debuggables") end, "Debuggables")

-- Expand the macro under the cursor
m("<leader>rm", function() vim.cmd.RustLsp("expandMacro") end, "Expand macro")

-- Open Cargo.toml for the current crate
m("<leader>rc", function() vim.cmd.RustLsp("openCargo") end, "Open Cargo.toml")

-- Jump to the parent module
m("<leader>rp", function() vim.cmd.RustLsp("parentModule") end, "Go to parent module")
