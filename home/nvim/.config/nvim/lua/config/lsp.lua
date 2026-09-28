-- LSP keymaps + inlay hints, wired on attach (applies to every LSP,
-- Rust and Haskell included via rustaceanvim / haskell-tools)
local map = vim.keymap.set

vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("user-lsp-attach", { clear = true }),
    callback = function(ev)
        local b = ev.buf
        local function m(keys, fn, desc)
            map("n", keys, fn, { buffer = b, desc = desc })
        end

        m("gd", vim.lsp.buf.definition, "Go to definition")
        m("gD", vim.lsp.buf.declaration, "Go to declaration")
        m("gr", vim.lsp.buf.references, "References")
        m("gi", vim.lsp.buf.implementation, "Implementation")
        m("K", vim.lsp.buf.hover, "Hover") -- Rust overrides this in after/ftplugin/rust.lua
        m("<leader>rn", vim.lsp.buf.rename, "Rename")
        m("<leader>ca", vim.lsp.buf.code_action, "Code action")
        m("<leader>d", vim.diagnostic.open_float, "Line diagnostics")
        m("[d", function() vim.diagnostic.jump({ count = -1, float = true }) end, "Prev diagnostic")
        m("]d", function() vim.diagnostic.jump({ count = 1, float = true }) end, "Next diagnostic")

        -- Toggle full virtual_lines for the WHOLE buffer (default: only current line)
        m("<leader>dl", function()
            local cfg = vim.diagnostic.config()
            local all = type(cfg.virtual_lines) == "table" and cfg.virtual_lines.current_line == true
            vim.diagnostic.config({ virtual_lines = all and true or { current_line = true } })
        end, "Toggle full diagnostic lines")

        -- Inlay hints on by default (great for Rust); <leader>ih toggles them
        if vim.lsp.inlay_hint then
            vim.lsp.inlay_hint.enable(true, { bufnr = b })
            m("<leader>ih", function()
                vim.lsp.inlay_hint.enable(
                    not vim.lsp.inlay_hint.is_enabled({ bufnr = b }),
                    { bufnr = b }
                )
            end, "Toggle inlay hints")
        end
    end,
})

-- Servers installed system-wide, configured in lsp/<name>.lua. Mason-managed
-- servers are enabled in lua/plugins/lsp.lua; Rust and Haskell are owned by
-- their own plugins (lua/plugins/lang.lua).
vim.lsp.enable({ "clangd", "verible" })
