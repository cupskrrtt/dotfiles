vim.pack.add({ "https://github.com/stevearc/conform.nvim" })

require("conform").setup({
	formatters_by_ft = {
		javascript = { "prettierd", stop_after_first = true },
		javascriptreact = { "prettierd", stop_after_first = true },
		typescript = { "prettierd", stop_after_first = true },
		typescriptreact = { "prettierd", stop_after_first = true },
		json = { "prettierd", stop_after_first = true },
		html = { "prettierd", stop_after_first = true },
		css = { "prettierd", stop_after_first = true },
		lua = { "stylua", stop_after_first = true },
		cs = { "csharpier", stop_after_first = true },
	},
	formatters = {
		csharpier = {
			command = "dotnet",
			args = {
				"csharpier",
				"format",
				"--write-stdout",
			},
			to_stdin = true,
		},
	},
})

vim.api.nvim_create_autocmd("BufWritePre", {
	pattern = "*",
	callback = function(args)
		require("conform").format({ bufnr = args.buf })
	end,
})
