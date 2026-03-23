return {
  'mrcjkb/rustaceanvim',
  version = '^8', -- Recommended
  lazy = false, -- This plugin is already lazy
  ft = { 'rust' },
  config = function()
    vim.g.rustaceanvim = {
      -- Plugin configuration
      tools = {},
      -- LSP configuration
      server = {
        on_attach = function(client, bufnr)
          local success, _ = pcall(vim.lsp.inlay_hint.enable, true)
          if not success then vim.lsp.inlay_hint.enable(0, true) end
        end,
        default_settings = {
          -- rust-analyzer language server configuration
          ['rust-analyzer'] = {
            cargo = {
              features = 'all',
            },
          },
        },
      },
      -- DAP configuration
      dap = {},
    }
  end,
}
