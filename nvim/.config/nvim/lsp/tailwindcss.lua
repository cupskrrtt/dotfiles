return {
	cmd = { "tailwindcss-language-server", "--stdio" },
	-- filetypes copied and adjusted from tailwindcss-intellisense
	filetypes = { "html", "css", "scss", "javascript", "javascriptreact", "typescript", "typescriptreact", "vue" },
	root_marker = { "package.json", "node_modules" },
}
