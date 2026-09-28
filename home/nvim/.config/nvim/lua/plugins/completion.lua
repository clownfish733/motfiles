return {
    "saghen/blink.cmp",
    dependencies = { "rafamadriz/friendly-snippets" },
    version = "1.*", -- prebuilt binaries; v2 is mid-breaking-changes, stay on 1
    opts = {
        -- default preset: <C-y> accept, <C-space> open/docs, <C-n>/<C-p> select
        keymap = { preset = "default" },
        appearance = { nerd_font_variant = "mono" },
        completion = {
            documentation = { auto_show = true, auto_show_delay_ms = 200 },
            accept = { auto_brackets = { enabled = true } },
        },
        -- crates.nvim completion arrives through the "lsp" source automatically
        sources = { default = { "lsp", "path", "snippets", "buffer" } },
        signature = { enabled = true },
        fuzzy = { implementation = "prefer_rust_with_warning" },
    },
    opts_extend = { "sources.default" },
}
