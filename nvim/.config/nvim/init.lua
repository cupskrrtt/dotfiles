local function build_fzf_native(path)
	if vim.fn.has("win32") == 0 then
		return vim.system({ "make" }, { cwd = path }):wait()
	end

	-- Windows: `make` isn't normally installed, so call a C compiler directly
	-- (same command the Makefile runs).
	for _, cc in ipairs({ "gcc", "clang", "cc", "zig" }) do
		if vim.fn.executable(cc) == 1 then
			vim.fn.mkdir(path .. "/build", "p")
			local cmd = cc == "zig" and { "zig", "cc" } or { cc }
			vim.list_extend(cmd, { "-O3", "-Wall", "-std=gnu99", "-D_CRT_SECURE_NO_WARNINGS", "-D_CRT_NONSTDC_NO_WARNINGS", "-shared", "src/fzf.c", "-o", "build/libfzf.dll" })
			return vim.system(cmd, { cwd = path }):wait()
		end
	end
	vim.notify("telescope-fzf-native: no C compiler (gcc/clang/zig) found", vim.log.levels.WARN)
end

local hooks = function(ev)
	local name, kind = ev.data.spec.name, ev.data.kind

	if name == "telescope-fzf-native.nvim" and (kind == "install" or kind == "update") then
		build_fzf_native(ev.data.path)
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
