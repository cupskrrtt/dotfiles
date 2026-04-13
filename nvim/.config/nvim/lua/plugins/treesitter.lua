return {
	"nvim-treesitter/nvim-treesitter",
	branch = "main",
	build = ":TSUpdate",
	config = function()
		require("nvim-treesitter").setup()

		local ensure_installed = {
			"javascript",
			"jsdoc",
			"diff",
			"typescript",
			"html",
			"tsx",
			"go",
			"css",
			"vue",
			"java",
			"csharp",
		}

		local installed = require("nvim-treesitter.config").get_installed()
		local to_install = vim.tbl_filter(function(p)
			return not vim.tbl_contains(installed, p)
		end, ensure_installed)

		if #to_install > 0 then
			require("nvim-treesitter").install(to_install)
		end

		vim.api.nvim_create_autocmd("FileType", {
			callback = function()
				pcall(vim.treesitter.start)
				vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
			end,
		})
	end,
}
