vim.lsp.enable({ "lua_ls", "ts_ls", "vue_ls" })

vim.diagnostic.config({
	--virtual_lines = true,
	--virtual_text = true,
	underline = true,
	update_in_insert = true,
	severity_sort = true,
})
