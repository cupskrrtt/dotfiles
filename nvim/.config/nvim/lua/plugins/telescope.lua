vim.pack.add({
	"https://github.com/nvim-telescope/telescope.nvim",
	"https://github.com/nvim-tree/nvim-web-devicons",
	"https://github.com/nvim-telescope/telescope-fzf-native.nvim",
	"https://github.com/nvim-lua/plenary.nvim",
})

require("telescope").setup({})
pcall(require("telescope").load_extension, "fzf")
