-- Merged on top of nvim-lspconfig's vtsls config; TS sends no hints unless asked.
local hints = {
	parameterNames = { enabled = "literals" },
	parameterTypes = { enabled = true },
	variableTypes = { enabled = true },
	propertyDeclarationTypes = { enabled = true },
	functionLikeReturnTypes = { enabled = true },
	enumMemberValues = { enabled = true },
}

return {
	settings = {
		typescript = { inlayHints = hints },
		javascript = { inlayHints = hints },
	},
}
