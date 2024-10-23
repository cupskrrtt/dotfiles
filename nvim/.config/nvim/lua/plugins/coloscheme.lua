return {
  {
    "folke/tokyonight.nvim",
    lazy = false,
    prority = 1000,
    config = function()
      vim.cmd([[colorscheme tokyonight-night]])
    end,
  }
}
