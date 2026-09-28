local map = vim.keymap.set

return {
    -- ---- Formatting (rustfmt handled by rust-analyzer; this covers the rest) --
    {
        "stevearc/conform.nvim",
        event = "BufWritePre",
        opts = {
            formatters_by_ft = {
                lua = { "stylua" },
                python = { "ruff_format" },
                haskell = { "stylish-haskell" },
                cabal = { "cabal_gild" },
            },
            -- conform ships a cabal_fmt builtin, but cabal-fmt is unmaintained
            -- and won't build against base >= 4.20 (GHC 9.10+). cabal-gild is
            -- the maintained replacement HLS also understands.
            formatters = {
                cabal_gild = {
                    command = "cabal-gild",
                    -- reads the buffer on stdin, writes formatted output to
                    -- stdout; --stdin tells it the real path so `-- cabal-gild:
                    -- discover` pragmas resolve relative to the .cabal file.
                    args = { "--stdin=$FILENAME" },
                    stdin = true,
                },
            },
            -- format on save; fall back to LSP formatting (rust-analyzer/rustfmt) when
            -- there's no dedicated formatter for the filetype
            format_on_save = { timeout_ms = 2000, lsp_format = "fallback" },
        },
        config = function(_, o)
            require("conform").setup(o)
            map("n", "<leader>cf", function()
                require("conform").format({ async = true, lsp_format = "fallback" })
            end, { desc = "Format buffer" })
        end,
    },

    -- ---- Linting -------------------------------------------------------------
    -- Most languages get their lint diagnostics from the LSP itself (clippy via
    -- rust-analyzer, clang-tidy via clangd, ruff). Haskell is the exception:
    -- HLS's ghcup bindist is built WITHOUT the hlint plugin (check with
    -- `haskell-language-server-9.10.3 --list-plugins`), so HLS only ever reports
    -- typecheck errors. hlint has to be driven as an external linter to get
    -- style hints ("Use concatMap", "Redundant $", ...) into the buffer.
    {
        "mfussenegger/nvim-lint",
        event = { "BufReadPost", "BufWritePost", "InsertLeave" },
        config = function()
            local lint = require("lint")
            lint.linters_by_ft = { haskell = { "hlint" } }

            vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost", "InsertLeave" }, {
                group = vim.api.nvim_create_augroup("nvim-lint", { clear = true }),
                callback = function() lint.try_lint() end,
            })

            map("n", "<leader>cl", function() lint.try_lint() end, { desc = "Lint buffer" })

            -- The autocmd above is registered while the plugin is being loaded
            -- BY BufReadPost, so it misses the very event that loaded it -- the
            -- first Haskell buffer you open would show no hints until the next
            -- write. Lint it explicitly to close that gap.
            vim.schedule(function() lint.try_lint() end)
        end,
    },
}
