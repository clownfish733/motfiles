return {
    -- ---- Theme: Monokai Pro -------------------------------------------------
    {
        "loctvl842/monokai-pro.nvim",
        lazy = false,
        priority = 1000, -- load before everything else so nothing flashes unthemed
        config = function()
            require("monokai-pro").setup({
                -- filters: classic | octagon | pro | machine | ristretto | spectrum
                filter = "pro",
                transparent_background = true, -- let WezTerm's window opacity show through
            })
            vim.cmd.colorscheme("monokai-pro")
        end,
    },

    -- ---- Statusline ---------------------------------------------------------
    {
        "nvim-lualine/lualine.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        opts = {
            options = {
                theme = "auto",
                globalstatus = true,
                section_separators = "",
                component_separators = "",
            },
        },
    },

    -- ---- Keybinding hints ---------------------------------------------------
    { "folke/which-key.nvim", event = "VeryLazy", opts = {} },

    -- ---- Inline colour swatches (#rrggbb, tailwind classes, css) ------------
    {
        "catgoose/nvim-colorizer.lua",
        event = "BufReadPre",
        opts = { user_default_options = { names = false, tailwind = true, css = true } },
    },

    -- ---- Centered / distraction-free editing --------------------------------
    {
        "folke/zen-mode.nvim",
        cmd = "ZenMode",
        keys = {
            { "<leader>z", "<cmd>ZenMode<cr>", desc = "Toggle Zen (centered) mode" },
        },
        opts = {
            window = {
                width = 125, -- columns of code; rest becomes side padding.
                -- Use a fraction (e.g. 0.75) for a % of screen width.
                options = {
                    number = true, -- keep line numbers (set false to hide)
                    relativenumber = true,
                    signcolumn = "yes",
                    cursorline = true,
                },
            },
        },
    },
}
