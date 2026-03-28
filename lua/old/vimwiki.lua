return {
  'vimwiki/vimwiki',
  init = function()
    vim.g.vimwiki_list = { {
      path = '~/Documents/Notes/vimwiki/',
      syntax = 'markdown',
      ext = '.md',
    } }
    vim.g.vimwiki_listsyms = '✗○◐●✓'
    vim.g.vimwiki_global_ext = 0
    vim.g.vimwiki_auto_header = 0
    vim.g.vimwiki_folding = 'expr' -- or 'list'
    -- No spaces in new note name
    vim.g.vimwiki_url_utils = 1
    vim.g.vimwiki_markdown_link_ext = 1
  end,
  config = function()
    vim.api.nvim_create_autocmd('FileType', {
      -- Note: Added 'markdown' to the pattern just in case
      pattern = { 'vimwiki', 'markdown' },
      callback = function()
        -- If you want Treesitter folding (modern Neovim way):
        vim.opt_local.foldmethod = 'expr'
        vim.opt_local.foldexpr = 'v:lua.vim.treesitter.foldexpr()'

        -- OR, if you want Vimwiki's native folding:
        -- vim.opt_local.foldmethod = 'expr'
        -- vim.opt_local.foldexpr = 'VimwikiFoldLevel(v:lnum)'

        vim.opt_local.foldlevel = 99
        vim.opt_local.foldenable = true
      end,
    })
  end,
}
