return {
	"cupskrrtt/nitpick",
	config = function()
		require("nitpick").setup({
			linter_by_ft = {
				typescriptreact = { "eslint_d", "eslint", "biome" },
				typescript = { "eslint_d", "eslint", "biome" },
				javascript = { "eslint_d", "eslint", "biome" },
				javascriptreact = { "eslint_d", "eslint", "biome" },
			},
		})
	end,
}
