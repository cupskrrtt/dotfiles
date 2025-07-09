local vue_language_server_path = vim.fn.stdpath("data")
	.. "/mason/packages/vue-language-server/node_modules/@vue/language-server"
-- Verify path exists
if vim.fn.isdirectory(vue_language_server_path) == 0 then
	print("Vue language server path not found: " .. vue_language_server_path)
	return
end

return {
	cmd = { "typescript-language-server", "--stdio" },
	filetypes = { "javascript", "typescript", "javascriptreact", "typescriptreact" },
	--init_options = {
	--	plugins = {
	--		{
	--			name = "@vue/typescript-plugin",
	--			location = vue_language_server_path,
	--			languages = { "vue", "typescript", "javascript" },
	--		},
	--	},
	--},
}
