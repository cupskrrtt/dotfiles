vim.pack.add({ "https://github.com/seblyng/roslyn.nvim" })

require("roslyn").setup({
	config = {
		cmd_env = {
			DOTNET_ROOT = vim.fn.expand("~/.dotnet"),
		},
		--cmd = {
		--	"dotnet",
		--	vim.fn.expand(
		--		"~/.local/share/roslyn-ls/content/LanguageServer/neutral/Microsoft.CodeAnalysis.LanguageServer.dll"
		--	),
		--	"--logLevel",
		--	"Information",
		--	"--extensionLogDirectory",
		--	vim.fs.joinpath(vim.fn.stdpath("cache"), "roslyn-logs"),
		--	"--stdio",
		--},
		settings = {
			["csharp|background_analysis"] = {
				-- Compiler errors everywhere (cheap: Roslyn compiles the solution anyway);
				-- analyzers (style/lint rules, the heavy part) only on open files.
				dotnet_compiler_diagnostics_scope = "fullSolution",
				dotnet_analyzer_diagnostics_scope = "openFiles",
			},
			["csharp|inlay_hints"] = {
				csharp_enable_inlay_hints_for_implicit_object_creation = true,
				csharp_enable_inlay_hints_for_implicit_variable_types = true,
				csharp_enable_inlay_hints_for_lambda_parameter_types = true,
				csharp_enable_inlay_hints_for_types = true,
				dotnet_enable_inlay_hints_for_parameters = true,
				dotnet_enable_inlay_hints_for_literal_parameters = true,
				dotnet_enable_inlay_hints_for_indexer_parameters = true,
				dotnet_enable_inlay_hints_for_object_creation_parameters = true,
				dotnet_enable_inlay_hints_for_other_parameters = true,
				-- Skip hints that just repeat what the code already says.
				dotnet_suppress_inlay_hints_for_parameters_that_differ_only_by_suffix = true,
				dotnet_suppress_inlay_hints_for_parameters_that_match_argument_name = true,
				dotnet_suppress_inlay_hints_for_parameters_that_match_method_intent = true,
			},
		},
	},

	filewatching = "roslyn",
})
