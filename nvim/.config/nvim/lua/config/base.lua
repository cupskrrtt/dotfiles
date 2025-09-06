-- Colors and Encoding
vim.o.termguicolors = true
vim.scriptencoding = "utf-8"
vim.opt.encoding = "utf-8"
vim.opt.fileencoding = "utf-8"

-- UI
vim.wo.number = true
vim.wo.relativenumber = true
vim.opt.title = true
vim.opt.hlsearch = true
vim.opt.showcmd = true
vim.opt.cmdheight = 1
vim.opt.laststatus = 2
vim.opt.scrolloff = 10
vim.opt.wrap = false -- no line wrap

-- Indentation (Prettier-friendly)
vim.opt.expandtab = false -- use tabs, not spaces
vim.opt.smarttab = true
vim.opt.autoindent = true
vim.opt.smartindent = true
vim.opt.breakindent = true
vim.opt.shiftwidth = 2 -- how many spaces to show for a tab (for display only)
vim.opt.tabstop = 2 -- how many spaces a tab counts for
vim.opt.softtabstop = 2 -- how many spaces when editing a tab
vim.opt.backspace = { "start", "eol", "indent" }

-- File and Backup
vim.g.backup = false
vim.g.writebackup = false
vim.g.swapfile = false
vim.opt.hidden = false

-- Search
vim.opt.ignorecase = true

-- Shell
vim.opt.shell = "zsh"

-- Leader key
vim.g.mapleader = " "

-- File navigation
vim.opt.path:append({ "**" })
vim.opt.wildignore:append({ "*/node_modules/*" })

-- Clipboard
vim.opt.clipboard:append({ "unnamedplus" })
