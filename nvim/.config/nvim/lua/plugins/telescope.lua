local hooks = function(ev)
	local name, kind = ev.data.spec.name, ev.data.kind

	if name == "telescope-fzf-native.nvim" and (kind == "install" or kind == "update") then
		vim.system(
			{ "cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release --target install" },
			{ cwd = ev.data.path }
		):wait()
	end
end

vim.api.nvim_create_autocmd("PackChanged", { callback = hooks })

vim.pack.add({
	"https://github.com/nvim-telescope/telescope.nvim",
	"https://github.com/BurntSushi/ripgrep",
	"https://github.com/sharkdp/fd",
	"https://github.com/nvim-tree/nvim-web-devicons",
	"https://github.com/nvim-telescope/telescope-fzf-native.nvim",
	"https://github.com/nvim-lua/plenary.nvim",
	"https://github.com/nvim-telescope/telescope-file-browser.nvim",
})

require("telescope").setup({
	extensions = {
		file_browser = {
			theme = "ivy",
			hijack_netrw = true,
		},
	},
})

--return {
--	"nvim-telescope/telescope.nvim",
--	tag = "0.1.8",
--	dependencies = { "nvim-lua/plenary.nvim", "BurntSushi/ripgrep" },
--	config = function()
--		require("telescope").setup({})
--	end,
--}
