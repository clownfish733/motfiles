-- Mason-managed LSP servers (everything except Rust/Haskell, which their own
-- plugins own, and clangd/verible, which are system installs in config/lsp.lua).
-- Neovim 0.12 native LSP: nvim-lspconfig ships the base configs, we tweak
-- with vim.lsp.config and turn them on with vim.lsp.enable.
return {
    "neovim/nvim-lspconfig",
    dependencies = {
        { "mason-org/mason.nvim", opts = {} },
        "mason-org/mason-lspconfig.nvim",
        "saghen/blink.cmp",
    },
    config = function()
        require("mason-lspconfig").setup({
            ensure_installed = { "lua_ls", "basedpyright", "ruff" },
            -- We enable servers ourselves below so rust-analyzer is never
            -- auto-enabled here (rustaceanvim owns it).
            automatic_enable = false,
        })

        -- Per-server overrides (blink's capabilities are merged automatically
        -- on 0.11+ when using vim.lsp.config, so no manual capabilities needed).
        vim.lsp.config("lua_ls", {
            settings = {
                Lua = {
                    diagnostics = { globals = { "vim" } },
                    workspace = { checkThirdParty = false },
                    telemetry = { enable = false },
                },
            },
        })

        vim.lsp.enable({ "lua_ls", "basedpyright", "ruff" })
    end,
}
