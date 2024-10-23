return {
  --LSP
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      { "hrsh7th/cmp-nvim-lsp" },
      { "hrsh7th/nvim-cmp" },
    },
    config = function()
      ---
      -- LSP Config
      ---
      local lspconfig = require("lspconfig")

      lspconfig.util.default_config.capabilities = vim.tbl_deep_extend(
        "force",
        lspconfig.util.default_config.capabilities,
        require("cmp_nvim_lsp").default_capabilities()
      )

      -- vim.api.nvim_create_autocmd("LspAttach", {
      --   desc = "LSP actions",
      --   callback = function(event)
      --     local opts = { buffer = event.buf }
      --     vim.keymap.set("n", "<leader>dh", ":lua vim.lsp.diagnostic.open_diagnostic()<CR>")
      --     vim.keymap.set("n", "<leader>dd", ":lua vim.lsp.buf.definition()<CR>")
      --     vim.keymap.set("n", "<leader>di", ":lua vim.lsp.buf.implementation()<CR>")
      --     vim.keymap.set("n", "<leader>dt", ":lua vim.lsp.buf.type_definition()<CR>")
      --     vim.keymap.set("n", "<leader>dr", ":lua vim.lsp.buf.references()<CR>")
      --     vim.keymap.set("n", "<leader>ca", ":lua vim.lsp.buf.code_action()<CR>")
      --   end
      -- })

      lspconfig.lua_ls.setup({})
      lspconfig.gopls.setup({})
      lspconfig.ts_ls.setup({})
      lspconfig.html.setup({
        filetypes = {
          "html",
          "templ",
          "javascriptreact",
          "typescriptreact"
        }
      })
      lspconfig.tailwindcss.setup {}
      lspconfig.cssls.setup {}

      ---
      -- Autocomplete setup
      ---
      local cmp = require("cmp")

      cmp.setup({
        sources = {
          { name = "nvim_lsp" }
        },
        snippet = {
          expand = function(args)
            vim.snippet.expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-k>"] = cmp.mapping.select_prev_item(),
          ["<C-j>"] = cmp.mapping.select_next_item(),
          ["<CR>"] = cmp.mapping.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = true, }),
        }),
      })
    end
  },
  --Formatter
  {
    "stevearc/conform.nvim",
    config = function()
      require("conform").setup({
        formatters_by_ft = {
          typescript = { "biome" },
          typescriptreact = { "biome" },
          json = { "biome" },
          html = { "biome" },
          css = { "biome" },
        },
        format_on_save = {
          timeout_ms = 500,
          lsp_format = "fallback"
        }
      })
    end
  },
  --Misc
  {
    "dmmulroy/ts-error-translator.nvim",
    config = function()
      require("ts-error-translator").setup({})
    end
  }
}
