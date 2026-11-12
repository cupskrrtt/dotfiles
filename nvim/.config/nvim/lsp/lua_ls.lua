return {
	settings = {
		Lua = {
			runtime = {
				version = "LuaJIT",
			},
			workspace = {
				-- Only Neovim's runtime + luv types; scanning every plugin made startup slow.
				library = {
					vim.env.VIMRUNTIME,
					"${3rd}/luv/library",
				},
				checkThirdParty = false,
			},
		},
	},
}
