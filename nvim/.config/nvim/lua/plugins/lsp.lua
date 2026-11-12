vim.pack.add({ "https://github.com/neovim/nvim-lspconfig" })

-- Inlay hints (inferred types, parameter names) on by default; <leader>th toggles.
vim.lsp.inlay_hint.enable(true)
vim.keymap.set("n", "<leader>th", function()
	vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
end, { desc = "Toggle inlay hints" })
