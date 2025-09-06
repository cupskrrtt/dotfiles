return {
	"lukas-reineke/indent-blankline.nvim",
	main = "ibl",
	---@module "ibl"
	---@type ibl.config
	opts = {
		indent = { char = "|" },
		scope = { enabled = true, show_start = true, show_end = false },
		whitespace = { remove_blankline_trail = true },
	},
}
