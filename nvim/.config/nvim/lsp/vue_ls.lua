return {
	cmd = { "vue-language-server", "--stdio" },
	filetypes = { "typescript", "javascript", "javascriptreact", "typescriptreact", "vue" },
	root_marker = {
		"vue.config.js",
		"vue.config.ts",
		"nuxt.config.js",
		"nuxt.config.ts",
	},
	init_options = {
		typescript = {
			-- replace with your global TypeScript library path
			tsdk = "/home/cup/.local/share/pnpm/global/5/node_modules/typescript/lib",
		},
	},
}
