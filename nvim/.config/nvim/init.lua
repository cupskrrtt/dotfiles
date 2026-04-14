vim.env.DOTNET_ROOT = "~/.dotnet/dotnet"

local hooks = function(ev)
	local name, kind = ev.data.spec.name, ev.data.kind

	if name == "blink.cmp" and (kind == "install" or kind == "update") then
		vim.system({ "cargo", "build", "--release" }, { cwd = ev.data.path }):wait()
	end

	if name == "telescope-fzf-native.nvim" and (kind == "install" or kind == "update") then
		vim.system(
			{ "cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release --target install" },
			{ cwd = ev.data.path }
		):wait()
	end
end

vim.api.nvim_create_autocmd("PackChanged", { callback = hooks })

require("options")
require("keymaps")
require("plugins.lsp")
require("plugins.dap")
require("plugins.mason")
require("plugins.blink")
require("plugins.colorscheme")
require("plugins.conform")
require("plugins.nvim-lint")
require("plugins.telescope")
require("plugins.treesitter")
require("plugins.roslyn")
--require("core.lsp")
