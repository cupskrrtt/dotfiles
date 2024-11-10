return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  config = function()
    local config = require("nvim-treesitter.configs")

    config.setup({
      ensure_installed = {
        "javascript",
        "jsdoc",
        "diff",
        "typescript",
        "html",
        "tsx",
        "go",
        "css",
      },
      highlight = {
        enable = true
      }
    })
  end
}
