vim.pack.add({ "https://github.com/stevearc/conform.nvim" })

require("conform").setup({
	formatters_by_ft = {
		javascript = { "prettierd" },
		javascriptreact = { "prettierd" },
		typescript = { "prettierd" },
		typescriptreact = { "prettierd" },
		json = { "prettierd" },
		html = { "prettierd" },
		css = { "prettierd" },
		lua = { "stylua" },
		cs = { "csharpier" },
		go = { "gofumpt" },
		python = { "ruff_format", "ruff_organize_imports" },
	},
	-- Filetypes without a formatter above fall back to the LSP's formatter.
	format_on_save = {
		timeout_ms = 500,
		lsp_format = "fallback",
	},
})
