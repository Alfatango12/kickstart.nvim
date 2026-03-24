return {
  {
    'tools-life/taskwiki',
    ft = { 'markdown', 'vimwiki' }, -- Only load for these filetypes
    init = function()
      -- Optional: Prevent taskwiki from handling every markdown file if it feels slow
      vim.g.taskwiki_dont_preserve_cursor = 1
    end,
    dependencies = {
      'vimwiki/vimwiki', -- taskwiki is designed to work on top of vimwiki
    },
    config = function()
      -- Your custom taskwiki logic/mappings go here
    end,
  },
}
