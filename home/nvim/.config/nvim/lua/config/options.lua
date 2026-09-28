local opt = vim.opt

opt.number = true
opt.relativenumber = true
opt.mouse = "a"
opt.showmode = false          -- lualine already shows the mode
opt.clipboard = "unnamedplus" -- use system clipboard
opt.breakindent = true
opt.undofile = true           -- persistent undo across sessions
opt.ignorecase = true
opt.smartcase = true          -- case-sensitive only if you type a capital
opt.signcolumn = "yes"        -- stops the text jumping when diagnostics appear
opt.updatetime = 250
opt.timeoutlen = 400
opt.splitright = true
opt.splitbelow = true
opt.inccommand = "split" -- live preview of :substitute
opt.cursorline = true
opt.scrolloff = 8
opt.termguicolors = true
opt.completeopt = "menuone,noselect"
opt.pumheight = 12 -- cap completion popup height

-- Indentation (LSP formatters like rustfmt override this per language)
opt.expandtab = true
opt.tabstop = 4
opt.shiftwidth = 4
opt.smartindent = true

-- Show invisible characters
opt.list = true
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
