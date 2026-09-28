local map = vim.keymap.set

return {
    -- ---- Fuzzy finder -------------------------------------------------------
    {
        "nvim-telescope/telescope.nvim",
        branch = "0.1.x",
        dependencies = {
            "nvim-lua/plenary.nvim",
            { "nvim-telescope/telescope-fzf-native.nvim", build = "make" }, -- needs cc + make
        },
        config = function()
            local telescope = require("telescope")
            telescope.setup({
                -- Telescope 0.1.x's TS previewer uses the old nvim-treesitter (master) API,
                -- which is incompatible with the main branch. Disable it; previews fall back
                -- to Vim regex syntax highlighting.
                defaults = { preview = { treesitter = false } },
            })
            pcall(telescope.load_extension, "fzf")
            local t = require("telescope.builtin")
            map("n", "<leader>ff", t.find_files, { desc = "Find files" })
            map("n", "<leader>fg", t.live_grep, { desc = "Live grep" })
            map("n", "<leader>fb", t.buffers, { desc = "Buffers" })
            map("n", "<leader>fh", t.help_tags, { desc = "Help tags" })
            map("n", "<leader>fd", t.diagnostics, { desc = "Diagnostics" })
            map("n", "<leader>fs", t.lsp_document_symbols, { desc = "Document symbols" })
            map("n", "<leader>fr", t.resume, { desc = "Resume last picker" })
        end,
    },

    -- ---- File explorer (buffer-based; edit the filesystem like text) ---------
    {
        "stevearc/oil.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        lazy = false,
        opts = { view_options = { show_hidden = true } },
        config = function(_, o)
            require("oil").setup(o)
            map("n", "-", "<cmd>Oil<CR>", { desc = "Open parent directory" })
        end,
    },

    -- ---- Git signs in the gutter --------------------------------------------
    { "lewis6991/gitsigns.nvim", opts = {} },

    -- ---- Autopairs ----------------------------------------------------------
    { "windwp/nvim-autopairs", event = "InsertEnter", opts = {} },
}
