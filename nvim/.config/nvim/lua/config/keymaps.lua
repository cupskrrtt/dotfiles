local keymap = vim.keymap

keymap.set("n", "<leader>fb", "<cmd>Explore<CR>")
keymap.set("n", "<C-a>", "gg<S-v>G")
keymap.set("n", "+", "<C-a>")
keymap.set("n", "-", "<C-x>")
keymap.set("n", "<leader>sh", "<cmd>split<CR>")
keymap.set("n", "<leader>sv", "<cmd>vsplit<CR>")
keymap.set("n", "sh", "<C-w>h")
keymap.set("n", "sj", "<C-w>j")
keymap.set("n", "sk", "<C-w>k")
keymap.set("n", "sl", "<C-w>l")
keymap.set("n", "<C-h>", ":bp<CR>")
keymap.set("n", "<C-l>", ":bn<CR>")
keymap.set("n", "<C-w>", ":BD<CR>")

keymap.set("n", "<leader>dh", ":lua vim.lsp.buf.hover()<CR>")
keymap.set("n", "<leader>do", ":lua vim.diagnostic.open_float()<CR>")
keymap.set("n", "<leader>dd", ":lua vim.lsp.buf.definition()<CR>")
keymap.set("n", "<leader>di", ":lua vim.lsp.buf.implementation()<CR>")
keymap.set("n", "<leader>dt", ":lua vim.lsp.buf.type_definition()<CR>")
keymap.set("n", "<leader>dr", ":lua vim.lsp.buf.references()<CR>")
keymap.set("n", "<leader>ca", ":lua vim.lsp.buf.code_action()<CR>")

