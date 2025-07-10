return {
	--LSP
	{
		"mason-org/mason-lspconfig.nvim",
		opts = {
			ensure_installed = {
				"lua_ls",
				"pyright",
				"ts_ls",
				"gopls",
				"vue_ls",
				"tailwindcss",
				"html",
				"cssls",
			},
			automatic_enable = {
				exclude = {
					"ts_ls",
					"vue_ls",
					"lua_ls",
				},
			},
		},
		dependencies = {
			{ "mason-org/mason.nvim", opts = {} },
			"neovim/nvim-lspconfig",
		},
	},

	--Formatter
	{
		"stevearc/conform.nvim",
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			require("conform").setup({
				formatters_by_ft = {
					javascript = { "biome", "prettier", stop_after_first = true },
					javascriptreact = { "biome", "prettier", stop_after_first = true },
					typescript = { "biome", "prettier", stop_after_first = true },
					typescriptreact = { "biome", "prettier", stop_after_first = true },
					json = { "biome", "prettier", stop_after_first = true },
					html = { "biome", "prettier", stop_after_first = true },
					css = { "biome", "prettier", stop_after_first = true },
					lua = { "stylua", stop_after_first = true },
					python = { "ruff_fix", "ruff_format", "ruff_organize_imports" },
				},
				format_after_save = {
					lsp_format = "fallback",
				},
			})
		end,
	},

	--Linter
	{
		"mfussenegger/nvim-lint",
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			local lint = require("lint")
			lint.linters_by_ft = {
				python = { "ruff" },
				javascript = { "eslint" },
				javascriptreact = { "eslint" },
				typescript = { "eslint" },
				typescriptreact = { "eslint" },
			}

			local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })

			vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "TextChanged" }, {
				group = lint_augroup,
				callback = function()
					lint.try_lint()
				end,
			})
		end,
	},
}
