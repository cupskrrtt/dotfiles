return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  config = function()
    local config = require("nvim-treesitter.configs")

    config.setup({
      ensure_installed = {
        "typescript",
        "html",
        "go",
        "css",
      },
      highlight = {
        enable = true
      }
    })
  end
}
