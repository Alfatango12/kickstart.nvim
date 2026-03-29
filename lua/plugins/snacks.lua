return {
  'folke/snacks.nvim',
  priority = 1000,
  lazy = false,
  opts = {
    indent = { enabled = true },
    scroll = { enabled = true },
    scratch = { enabled = true }, -- Enable scratch module
  },
  keys = {
    {
      '<leader>td',
      function()
        -- This opens a persistent scratch buffer mapped to a file in your vault
        require('snacks').scratch {
          name = 'Global Todo',
          ft = 'markdown',
          file = '~/Documents/Notes/masterVault/202603291443-todo.md',
        }
      end,
      desc = 'Open Todo Scratch',
    },
  },
}
