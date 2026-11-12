local hooks = function(ev)
	local name, kind = ev.data.spec.name, ev.data.kind

	if name == "telescope-fzf-native.nvim" and (kind == "install" or kind == "update") then
		vim.system({ "make" }, { cwd = ev.data.path }):wait()
	end
end

vim.api.nvim_create_autocmd("PackChanged", { callback = hooks })

require("options")
require("keymaps")
require("plugins.lsp")
require("plugins.mason") -- before dap: mason-nvim-dap needs mason set up
require("plugins.dap")
require("plugins.blink")
require("plugins.colorscheme")
require("plugins.conform")
require("plugins.nvim-lint")
require("plugins.telescope")
require("plugins.treesitter")
require("plugins.roslyn")
require("plugins.markdown")
