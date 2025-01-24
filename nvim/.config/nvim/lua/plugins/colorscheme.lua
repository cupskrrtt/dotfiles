return {
  {
    "folke/tokyonight.nvim",
    lazy = false,
    prority = 1000,
    config = function()
      require("tokyonight").setup({
        style = "night",
        transparent = true,
        sidebars = "transparent"
      })
      vim.cmd([[colorscheme tokyonight-night]])
    end

  },
}
