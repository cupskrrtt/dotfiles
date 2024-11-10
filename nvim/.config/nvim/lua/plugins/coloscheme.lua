return {
  {
    "folke/tokyonight.nvim",
    lazy = false,
    prority = 1000,
    opts = {
      style = "night",
      sidebars = "transparent",
      transparent = true
    }
  },

  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "tokyonight",
    },
  },
}
