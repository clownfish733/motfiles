vim.bo.shiftwidth = 4
vim.bo.tabstop = 4
vim.bo.expandtab = true
vim.bo.commentstring = "// %s"
vim.bo.cindent = true

local map = function(lhs, rhs, desc)
    vim.keymap.set("n", lhs, rhs, { buffer = 0, desc = desc })
end

-- swap between .cpp and .hpp
map("<leader>a", function()
    local bufnr = vim.api.nvim_get_current_buf()
    local client = vim.lsp.get_clients({ bufnr = bufnr, name = "clangd" })[1]
    if not client then return vim.notify("clangd not attached", vim.log.levels.WARN) end
    client:request("textDocument/switchSourceHeader",
        vim.lsp.util.make_text_document_params(bufnr),
        function(err, result)
            if err or not result then return vim.notify("no corresponding file", vim.log.levels.WARN) end
            vim.cmd.edit(vim.uri_to_fname(result))
        end, bufnr)
end, "Switch source/header")
