-- ~/.config/nvim/after/ftplugin/haskell.lua
-- Haskell-only keymaps, using haskell-tools.nvim's richer commands (mirrors
-- the rustaceanvim setup in after/ftplugin/rust.lua). Generic LSP maps (gd,
-- gr, K, <leader>ca, rename, diagnostics, inlay hints) still come from the
-- LspAttach autocmd in init.lua.

local ht = require("haskell-tools")
local bufnr = vim.api.nvim_get_current_buf()
local function m(keys, fn, desc)
  vim.keymap.set("n", keys, fn, { buffer = bufnr, desc = desc, silent = true })
end

-- HLS leans heavily on code lenses (run/add-type-signature); run the one under
-- the cursor.
m("<leader>hc", vim.lsp.codelens.run, "Run code lens")

-- Toggle a GHCi repl for the current package, or just the current buffer.
m("<leader>hr", ht.repl.toggle, "Toggle GHCi repl (package)")
m("<leader>hR", function() ht.repl.toggle(vim.api.nvim_buf_get_name(bufnr)) end, "Toggle GHCi repl (buffer)")
m("<leader>hq", ht.repl.quit, "Quit GHCi repl")

-- Evaluate all the {- $> ... <$ -} eval comments in the buffer via HLS.
m("<leader>he", ht.lsp.buf_eval_all, "Eval all eval-comments")

-- Hoogle search for the type signature of the symbol under the cursor.
m("<leader>hs", ht.hoogle.hoogle_signature, "Hoogle signature search")

-- Restart HLS for this project (useful after editing .cabal / package.yaml).
m("<leader>hl", function() vim.cmd("LspRestart") end, "Restart HLS")
