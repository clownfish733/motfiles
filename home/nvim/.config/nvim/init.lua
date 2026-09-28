-- ~/.config/nvim/init.lua
-- Neovim 0.12+ config. Rust-first (rustaceanvim) but sane for everything else.
-- Theme: Monokai Pro. Plugin manager: lazy.nvim. Completion: blink.cmp.
--
-- Layout:
--   lua/config/   core editor settings (no plugins)
--   lua/plugins/  one lazy.nvim spec file per area, auto-imported
--   lsp/          native vim.lsp server configs (picked up by vim.lsp.enable)
--   after/ftplugin/  per-filetype settings and keymaps

-- Leader must be set BEFORE lazy/plugins load
vim.g.mapleader = " "
vim.g.maplocalleader = " "

require("config.options")
require("config.keymaps")
require("config.diagnostics")
require("config.lsp")
require("config.lazy")
