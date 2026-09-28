return {
    -- ---- Rendered markdown in the buffer ------------------------------------
    {
        "OXY2DEV/markview.nvim",
        lazy = false,
        dependencies = { "saghen/blink.cmp" },
        opts = {
            preview = {
                modes = { "n", "no", "c" },
                hybrid_modes = { "n" },
            },
        },
    },

    -- ---- Inline image rendering (Kitty graphics protocol via WezTerm) --------
    {
        "3rd/image.nvim",
        ft = { "markdown", "vimwiki" },
        build = false, -- skip the luarocks/magick rock build; magick_cli doesn't need it
        opts = {
            backend = "kitty",
            processor = "magick_cli", -- use the `magick` CLI (no luarock needed)
            integrations = {
                markdown = {
                    enabled = true,
                    only_render_image_at_cursor = false,
                    filetypes = { "markdown", "vimwiki" },
                },
            },
            max_width = 100,
            max_height = 20,
            window_overlap_clear_enabled = true,
            window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "" },
        },
    },
}
