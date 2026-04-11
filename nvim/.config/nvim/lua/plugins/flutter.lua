return {
	"akinsho/flutter-tools.nvim",
	lazy = false, -- Load on startup
	dependencies = {
		"nvim-lua/plenary.nvim",
		"stevearc/dressing.nvim", -- Optional, for better UI selection
	},
	config = function()
		require("flutter-tools").setup({
			-- Customize your settings here. Common options:
			-- flutter_path = '...', -- full path if needed
			-- debugger = { enabled = true, ... },
			-- lsp = { settings = { showtodos = true, ... } },
		})
	end,
}
