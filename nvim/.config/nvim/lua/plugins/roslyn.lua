vim.pack.add({ "https://github.com/seblyng/roslyn.nvim" })

require("roslyn").setup({
	config = {
		cmd = {
			"dotnet",
			vim.fn.expand(
				"~/.local/share/roslyn-ls/content/LanguageServer/neutral/Microsoft.CodeAnalysis.LanguageServer.dll"
			),
			"--logLevel",
			"Information",
			"--extensionLogDirectory",
			vim.fs.joinpath(vim.fn.stdpath("cache"), "roslyn-logs"),
			"--stdio",
		},
		settings = {
			["csharp|background_analysis"] = {
				dotnet_analyzer_diagnostics_scope = "fullSolution",
				dotnet_compiler_diagnostics_scope = "fullSolution",
			},
		},
	},

	filewatching = "roslyn",
})
