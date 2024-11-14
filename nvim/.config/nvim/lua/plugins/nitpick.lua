return {
  "cupskrrtt/nitpick",
  config = function()
    require("nitpick").setup({
      linter_by_ft = {
        typescriptreact = { "eslint_d", "eslint", "biome" },
        javascript = { "eslint_", "eslint" },
      },
    })
  end,
}
