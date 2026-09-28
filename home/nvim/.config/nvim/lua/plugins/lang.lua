-- Language-specific tooling. Per-filetype keymaps live in after/ftplugin/.
return {
    -- ---- Rust (owns rust-analyzer end-to-end; do NOT configure it elsewhere) --
    {
        "mrcjkb/rustaceanvim",
        version = "^9", -- requires Neovim 0.12; use "^8" if you drop to 0.11
        lazy = false,   -- it lazy-loads itself on rust files
        init = function()
            vim.g.rustaceanvim = {
                server = {
                    default_settings = {
                        ["rust-analyzer"] = {
                            cargo = { allFeatures = true, buildScripts = { enable = true } },
                            checkOnSave = true,
                            check = { command = "clippy" }, -- lint with clippy on save
                            procMacro = { enable = true },
                            inlayHints = {
                                bindingModeHints = { enable = true },
                                closureReturnTypeHints = { enable = "always" },
                                lifetimeElisionHints = { enable = "skip_trivial" },
                            },
                        },
                    },
                },
            }
        end,
    },

    -- ---- Cargo.toml superpowers (versions, features, completion via LSP) -----
    {
        "saecki/crates.nvim",
        event = { "BufRead Cargo.toml" },
        opts = {
            completion = { crates = { enabled = true } },
            lsp = { enabled = true, actions = true, completion = true, hover = true },
        },
    },

    -- ---- Haskell (owns haskell-language-server end-to-end, like rustaceanvim
    --      does for rust-analyzer; do NOT configure hls via lspconfig) ---------
    {
        "mrcjkb/haskell-tools.nvim",
        version = "^10", -- requires Neovim 0.10+
        lazy = false,    -- it lazy-loads itself on haskell/cabal files
        init = function()
            -- All config goes through vim.g.haskell_tools; the plugin reads it
            -- when the first Haskell buffer opens and starts HLS itself.
            vim.g.haskell_tools = {
                hls = {
                    default_settings = {
                        haskell = {
                            -- conform runs stylish-haskell on save; point HLS at
                            -- it too so any stray LSP format request succeeds.
                            formattingProvider = "stylish-haskell",
                            -- cabal files need a cabal-aware formatter, not
                            -- stylish-haskell, or HLS chokes parsing the .cabal.
                            cabalFormattingProvider = "cabal-gild",
                            checkProject = true,
                        },
                    },
                },
            }
        end,
    },

    -- ---- LaTeX (vimtex owns compilation + viewer) ---------------------------
    {
        "lervag/vimtex",
        lazy = false,
        init = function()
            vim.g.vimtex_view_method = "zathura"
            vim.g.vimtex_compiler_method = "latexmk"
            vim.g.vimtex_quickfix_mode = 0
        end,
    },
}
