return {
	--LSP
	{
		"mason-org/mason-lspconfig.nvim",
		opts = {
			ensure_installed = {
				"lua_ls",
				"pyright",
				"gopls",
				"vue_ls",
				"tailwindcss",
				"html",
				"cssls",
			},
			automatic_enable = {
				exclude = {
					"vtsls",
					"vue_ls",
					"lua_ls",
				},
			},
		},
		dependencies = {
			{
				"mason-org/mason.nvim",
				opts = {
					registries = {
						"github:mason-org/mason-registry",
						"github:Crashdummyy/mason-registry",
					},
				},
			},
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
					javascript = { "biome", "prettier", "prettierd", stop_after_first = true },
					javascriptreact = { "biome", "prettier", "prettierd", stop_after_first = true },
					typescript = { "biome", "prettier", "prettierd", stop_after_first = true },
					typescriptreact = { "biome", "prettier", "prettierd", stop_after_first = true },
					json = { "biome", "prettier", "prettierd", stop_after_first = true },
					html = { "biome", "prettier", "prettierd", stop_after_first = true },
					css = { "biome", "prettier", "prettierd", stop_after_first = true },
					lua = { "stylua", stop_after_first = true },
					python = { "ruff_fix", "ruff_format", "ruff_organize_imports" },
					vue = { "prettier", "prettierd", stop_after_first = true },
					cs = { "csharpier", stop_after_first = true },
				},
				format_after_save = {
					lsp_format = "fallback",
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
				javascript = { "biomejs" },
				javascriptreact = { "biomejs" },
				typescript = { "biomejs" },
				typescriptreact = { "biomejs" },
				vue = { "eslint_d" },
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
