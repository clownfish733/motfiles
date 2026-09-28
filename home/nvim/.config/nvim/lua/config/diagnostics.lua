-- Needs a Nerd Font for the sign glyphs; swap to plain text like "E"/"W" if
-- you don't have one.
vim.diagnostic.config({
    -- short inline text, but NOT on the current line (virtual_lines covers it there
    -- with full wrapping, so this avoids showing the message twice)
    virtual_text = { current_line = false },
    -- full, wrapped, multi-line diagnostic rendered UNDER the current line — this is
    -- what stops long Rust/clippy errors running off the right edge of the screen
    virtual_lines = { current_line = true },
    severity_sort = true,
    float = { border = "rounded", source = true, wrap = true, max_width = 100 },
    signs = {
        text = {
            [vim.diagnostic.severity.ERROR] = "",
            [vim.diagnostic.severity.WARN] = "",
            [vim.diagnostic.severity.INFO] = "",
            [vim.diagnostic.severity.HINT] = "",
        },
    },
})
