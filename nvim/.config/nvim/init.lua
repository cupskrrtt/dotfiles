require("config.lazy")
require("config.base")
require("config.keymaps")
require("config.highlight")
require("core.lsp")

--local vue_ls_config = {
--  on_init = function(client)
--    client.handlers['tsserver/request'] = function(_, result, context)
--      local clients = vim.lsp.get_clients({ bufnr = context.bufnr, name = 'vtsls' })
--      if #clients == 0 then
--        vim.notify('Could not found `vtsls` lsp client, vue_lsp would not work without it.', vim.log.levels.ERROR)
--        return
--      end
--      local ts_client = clients[1]
--
--      local param = unpack(result)
--      local id, command, payload = unpack(param)
--      ts_client:exec_cmd({
--        command = 'typescript.tsserverRequest',
--        arguments = {
--          command,
--          payload,
--        },
--      }, { bufnr = context.bufnr }, function(_, r)
--        local response_data = { { id, r.body } }
--        ---@diagnostic disable-next-line: param-type-mismatch
--        client:notify('tsserver/response', response_data)
--      end)
--    end
--  end,
--}
--
--vim.lsp.config('vue_ls', vue_ls_config)
--
--vim.lsp.enable({ 'lua_ls', 'html', 'ts_ls', 'vue_lsp' })
