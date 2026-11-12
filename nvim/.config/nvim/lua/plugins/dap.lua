vim.pack.add({
	"https://github.com/mfussenegger/nvim-dap",
	"https://github.com/nvim-neotest/nvim-nio",
	"https://github.com/rcarriga/nvim-dap-ui",
	"https://github.com/leoluz/nvim-dap-go",
	"https://github.com/jay-babu/mason-nvim-dap.nvim",
})

local dap = require("dap")
require("dap-go").setup()

-- Inside Hiero, the debug views are Hiero panes (output, repl, watches,
-- variables, stack, breakpoints); outside it, dap-ui shows them in nvim.
local in_hiero = (vim.env.HIERO_PANE or "") ~= ""
local toggle_ui

if in_hiero then
	-- lua/hiero is a copy of hiero's nvim/lua/hiero (github.com/cupskrrtt/hiero).
	local hiero = require("hiero.dap")
	hiero.setup({ dir = "down", size = 30 })
	toggle_ui = hiero.toggle_panels
else
	local dapui = require("dapui")
	dapui.setup({
		controls = {
			enabled = false,
		},
	})
	dap.listeners.before.attach.dapui_config = function()
		dapui.open()
	end
	dap.listeners.before.launch.dapui_config = function()
		dapui.open()
	end
	dap.listeners.before.event_terminated.dapui_config = function()
		dapui.close()
	end
	dap.listeners.before.event_exited.dapui_config = function()
		dapui.close()
	end
	toggle_ui = dapui.toggle
end

-- Debuggers: mason-nvim-dap installs them and registers each adapter plus a
-- default launch config. To debug a new language, add its name here (or
-- :MasonInstall it); see :h mason-nvim-dap for the names.
local mason_dap = require("mason-nvim-dap")
mason_dap.setup({
	ensure_installed = { "coreclr", "delve" },
	-- Debuggers without an entry here use mason-nvim-dap's built-in defaults.
	handlers = {
		-- C#: F5 picks a launchSettings.json profile, stops a running instance,
		-- builds just that project, then launches (see lua/dotnet_debug.lua).
		coreclr = function(config)
			local dotnet = require("dotnet_debug")
			config.configurations = {} -- provided per buffer by dotnet_debug
			config.adapters = vim.tbl_extend("force", config.adapters, { enrich_config = dotnet.enrich })
			mason_dap.default_setup(config)
			dotnet.setup()
		end,

		-- Go: dap-go already provides the launch configs (incl. debug test);
		-- only register the adapter so the menu has no duplicates.
		delve = function(config)
			config.configurations = {}
			mason_dap.default_setup(config)
		end,
	},
})

local map = vim.keymap.set

map("n", "<F4>", dap.terminate)
map("n", "<F5>", dap.continue)
map("n", "<F7>", toggle_ui)
map("n", "<F9>", dap.toggle_breakpoint)
map("n", "<F10>", dap.step_over)
map("n", "<F11>", dap.step_into)
map("n", "<F12>", dap.step_out)
