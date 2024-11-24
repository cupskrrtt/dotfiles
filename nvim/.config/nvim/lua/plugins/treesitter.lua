return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  config = function()
    local config = require("nvim-treesitter.configs")

    config.setup({
      sync_install = true,
      auto_install = false,
      ignore_install = {},
      modules = {},
      ensure_installed = {
        "javascript",
        "jsdoc",
        "diff",
        "typescript",
        "html",
        "tsx",
        "go",
        "css",
        "prisma"
      },
      highlight = {
        enable = true
      }
    })
  end
}
