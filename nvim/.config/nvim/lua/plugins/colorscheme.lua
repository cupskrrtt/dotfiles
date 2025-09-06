--return {
--	{
--		"folke/tokyonight.nvim",
--		lazy = false,
--		prority = 1000,
--		config = function()
--			require("tokyonight").setup({
--				style = "night",
--				transparent = true,
--				sidebars = "transparent",
--			})
--			vim.cmd([[colorscheme tokyonight-night]])
--		end,
--	},
--}
--
--return {
--	{
--		"olimorris/onedarkpro.nvim",
--		priority = 1000, -- Ensure it loads first
--		config = function()
--			vim.cmd([[colorscheme onedark_dark]])
--		end,
--	},
--}

--return {
--	"rose-pine/neovim",
--	name = "rose-pine",
--	config = function()
--		vim.cmd("colorscheme rose-pine")
--	end,
--}

return {
	"vague2k/vague.nvim",
	lazy = false, -- make sure we load this during startup if it is your main colorscheme
	priority = 1000, -- make sure to load this before all the other plugins
	config = function()
		-- NOTE: you do not need to call setup if you don't want to.
		require("vague").setup({
			-- optional configuration here
			trasnparent = true,
		})
		vim.cmd("colorscheme vague")
	end,
}
