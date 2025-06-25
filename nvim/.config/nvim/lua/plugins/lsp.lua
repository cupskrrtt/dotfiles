return {
  --LSP
  {
    "mason-org/mason-lspconfig.nvim",
    opts = {
      ensure_installed = { "lua_ls", "pyright", "ts_ls", "gopls", "vue_ls", "tailwindcss", "html", "cssls" },
    },
    dependencies = {
      {
        "mason-org/mason.nvim",
        opts = {}
      },
      "neovim/nvim-lspconfig",
    },
  },

  --Completion
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
    },
    config = function()
      vim.opt.completeopt = { "menu", "menuone", "noselect" }

      require("luasnip.loaders.from_vscode").lazy_load()

      local cmp = require("cmp")
      local luasnip = require("luasnip")

      cmp.setup({
        sources = cmp.config.sources({
          {
            name = "nvim_lsp",
            keyword_length = 1,
            entry_filter = function(entry, ctx)
              -- Check if the buffer type is 'vue'
              if ctx.filetype ~= 'vue' then
                return true
              end

              local cursor_before_line = ctx.cursor_before_line
              -- For events
              if cursor_before_line:sub(-1) == '@' then
                return entry.completion_item.label:match('^@')
                -- For props also exclude events with `:on-` prefix
              elseif cursor_before_line:sub(-1) == ':' then
                return entry.completion_item.label:match('^:') and not entry.completion_item.label:match('^:on%-')
              else
                return true
              end
            end
          },
          { name = "luasnip", keyword_length = 2 },
        }),
        window = {
          documentation = cmp.config.window.bordered(),
        },
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-k>"] = cmp.mapping.select_prev_item(),
          ["<C-j>"] = cmp.mapping.select_next_item(),
          ["<CR>"] = cmp.mapping.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = true }),
        }),
      })
    end,
  },

  --Formatter
  {
    "stevearc/conform.nvim",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      require("conform").setup({
        formatters_by_ft = {
          javascript = { "biome", "prettier", stop_after_first = true },
          javascriptreact = { "biome", "prettier", stop_after_first = true },
          typescript = { "biome", "prettier", stop_after_first = true },
          typescriptreact = { "biome", "prettier", stop_after_first = true },
          json = { "biome", "prettier", stop_after_first = true },
          html = { "biome", "prettier", stop_after_first = true },
          css = { "biome", "prettier", stop_after_first = true },
          lua = { "stylua", stop_after_first = true },
          python = { "ruff_fix", "ruff_format", "ruff_organize_imports" }
        },
        format_after_save = {
          lsp_format = "fallback",
        },
      })
    end,
  },

  --Linter
  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      local lint = require("lint")
      lint.linters_by_ft = {
        python = { "ruff" },
        javascript = { "eslint" },
        javascriptreact = { "eslint" },
        typescript = { "eslint" },
        typescriptreact = { "eslint" },
      }

      local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })

      vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "TextChanged" }, {
        group = lint_augroup,
        callback = function()
          lint.try_lint()
        end,
      })
    end
  }
}
