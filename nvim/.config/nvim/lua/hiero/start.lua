-- Start file of a panel pane: nvim --clean -u <this> -- <kind> <server of the main nvim>
-- This file is <root>/lua/hiero/start.lua; <root> goes on the runtimepath.
local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h:h")
vim.opt.rtp:prepend(root)
local args = vim.fn.argv()
-- The two words are ours, not files to edit.
vim.cmd("silent! %argdelete")
for _, b in ipairs(vim.api.nvim_list_bufs()) do
  if vim.api.nvim_buf_get_name(b) ~= "" then
    pcall(vim.api.nvim_buf_delete, b, { force = true })
  end
end
require("hiero.panel").start(args[1], args[2])
