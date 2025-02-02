return {
  --LSP
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      { "hrsh7th/cmp-nvim-lsp" },
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
      
      lspconfig.lua_ls.setup({
        settings = {
          Lua = {
            runtime = {
              version = "LuaJIT", -- Lua version
              path = vim.split(package.path, ';'),
            },
            diagnostics = {
              globals = { "vim", "love", "jit" },
            },
            workspace = {
              checkThirdParty = true,
              library = {
                vim.env.VIMRUNTIME,
                '${3rd}/love2d/library'
              }
            },
          },
        },
      })
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
      lspconfig.tailwindcss.setup({
        settings = {
          tailwindCSS = {
            experimental = {
              classRegex = {
                { "cva\\(([^)]*)\\)", "[\"'`]([^\"'`]*).*?[\"'`]" },
                { "cx\\(([^)]*)\\)",  "(?:'|\"|`)([^']*)(?:'|\"|`)" }
              }
            }
          }
        }
      })
      lspconfig.prismals.setup({})
      lspconfig.cssls.setup({})
      lspconfig.sqlls.setup({
        cmd = { "sql-language-server", "up", "--method", "stdio" },
      })
    end
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
        sources = cmp.config.sources {
          { name = "nvim_lsp", keyword_length = 1 },
          { name = "luasnip",  keyword_length = 2 }
        },
        window = {
          documentation = cmp.config.window.bordered()
        },
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
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
          lua = { "stylua", stop_after_first = true}
        },
        format_after_save = {
          lsp_format = "fallback",
        }
      })
    end
  },
}
