vim.pack.add({
	"https://github.com/mfussenegger/nvim-dap",
	"https://github.com/nvim-neotest/nvim-nio",
	"https://github.com/rcarriga/nvim-dap-ui",
})

local dap, dapui = require("dap"), require("dapui")

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

--Keymaps
dap.adapters.coreclr = {
	type = "executable",
	command = vim.fn.stdpath("data") .. "/mason/bin/netcoredbg",
	args = { "--interpreter=vscode" },
}

dap.configurations.cs = {
	{
		type = "coreclr",
		name = "Launch",
		request = "launch",
		program = function()
			local project = vim.fn.getcwd()
			vim.fn.system("dotnet build " .. project)
			-- get only the first dll matching the project name
			local dlls = vim.fn.globpath(project .. "/bin/Debug", "**/*.dll", false, true)
			-- filter to find the main project dll (not dependencies)
			for _, dll in ipairs(dlls) do
				local name = vim.fn.fnamemodify(dll, ":t")
				if not name:match("^Microsoft") and not name:match("^System") then
					return dll
				end
			end
		end,
	},
}

local map = vim.keymap.set

map("n", "<F4>", dap.terminate)
map("n", "<F5>", dap.continue)
map("n", "<F7>", dapui.toggle)
map("n", "<F9>", dap.toggle_breakpoint)
map("n", "<F10>", dap.step_into)
map("n", "<F11>", dap.step_over)
map("n", "<F12>", dap.step_out)
