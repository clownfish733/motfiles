-- Syntax highlighting, indent, folds
return {
    "nvim-treesitter/nvim-treesitter",
    branch = "main", -- main is the branch maintained for Neovim 0.11+/0.12; master is frozen & crashes on 0.12's query API
    build = ":TSUpdate",
    config = function()
        require("nvim-treesitter").install({
            "rust", "toml", "lua", "vimdoc", "python", "bash", "regex",
            "json", "yaml", "markdown", "markdown_inline", "c", "cpp",
            "javascript", "typescript", "html", "css", "cmake",
            "haskell",
        })

        vim.api.nvim_create_autocmd("FileType", {
            callback = function(ev)
                -- enable treesitter highlighting if a parser is available
                if not pcall(vim.treesitter.start, ev.buf) then return end
                -- treesitter-based indentation
                vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
            end,
        })
    end,
}
