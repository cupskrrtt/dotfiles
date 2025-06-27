vim.lsp.enable({ "lua_ls", "html", "ts_ls", "vue_ls", "tailwindcss", "cssls" })

vim.diagnostic.config({
	virtual_lines = true,
	--virtual_text = true,
	underline = true,
	update_in_insert = true,
	severity_sort = true,
})
