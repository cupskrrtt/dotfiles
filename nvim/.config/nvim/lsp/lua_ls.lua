return {
	settings = {
		Lua = {
			diagnostics = {
				globals = { "vim" },
			},
			runtime = {
				version = "LuaJIT",
			},
			workspace = {
				library = vim.list_extend(
					vim.api.nvim_get_runtime_file("", true),
					{ vim.fn.stdpath("data") .. "/site/pack/core/opt" }
				),
				checkThirdParty = false,
			},
		},
	},
}
