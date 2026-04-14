vim.pack.add({ "https://github.com/nvim-treesitter/nvim-treesitter" })

require("nvim-treesitter").setup({
	install_dir = vim.fn.stdpath("data") .. "/site",
})

local ensure_installed = {
	"javascript",
	"jsdoc",
	"diff",
	"typescript",
	"html",
	"tsx",
	"go",
	"css",
	"java",
	"c_sharp",
}

local installed = require("nvim-treesitter.config").get_installed()
local to_install = vim.tbl_filter(function(p)
	return not vim.tbl_contains(installed, p)
end, ensure_installed)

if #to_install > 0 then
	require("nvim-treesitter").install(to_install)
end

vim.api.nvim_create_autocmd("FileType", {
	pattern = { "<filetype>" },
	callback = function()
		vim.treesitter.start()
	end,
})
