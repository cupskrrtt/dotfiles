vim.pack.add({ "https://github.com/saghen/blink.cmp" })

require("blink.cmp").setup({
	keymap = {
		preset = "none",
		["<C-k>"] = { "select_prev", "fallback" },
		["<C-j>"] = { "select_next", "fallback" },
		["<CR>"] = { "accept", "fallback" },
	},

	appearance = {
		nerd_font_variant = "mono",
	},

	completion = { documentation = { auto_show = true } },

	sources = {
		default = { "lsp", "path" },
		--per_filetype = {
		--	sql = { "dadbod", "buffer" },
		--},
		--providers = {
		--	dadbod = { name = "Dabbod", module = "vim_dadbod_completion.blink" },
		--},
	},

	fuzzy = {
		implementation = "prefer_rust_with_warning",
	},
})
