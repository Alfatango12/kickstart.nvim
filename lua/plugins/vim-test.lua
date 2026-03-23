return {
  'vim-test/vim-test',
  dependencies = {
    'preservim/vimux',
  },

  keys = {
    { '<leader>tsn', '<cmd>TestNearest<cr>', desc = 'Test Nearest' },
    { '<leader>tsf', '<cmd>TestFile<cr>', desc = 'Test File' },
    { '<leader>tsa', '<cmd>TestSuite<cr>', desc = 'Test Suite' },
    { '<leader>tsl', '<cmd>TestLast<cr>', desc = 'Test Last' },
    { '<leader>tsv', '<cmd>TestVisit<cr>', desc = 'Test Visit' },
  },

  config = function()
    vim.g['test#strategy'] = 'vimux'
    vim.g.VimuxOrientation = 'h'
    vim.g.VimuxHeight = '25'
  end,
}
