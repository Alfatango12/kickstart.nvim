return {
  {
    'tools-life/taskwiki',
    --[[ dependencies = {
      'powerman/taskwarrior-vim',
    }, ]]
    ft = { 'markdown', 'vimwiki' }, -- Only load for these filetypes
    init = function()
      -- Optional: Prevent taskwiki from handling every markdown file if it feels slow
      vim.g.taskwiki_dont_preserve_cursor = 1
    end,
    dependencies = {
      'vimwiki/vimwiki', -- taskwiki is designed to work on top of vimwiki
    },
    config = function()
      vim.api.nvim_create_autocmd('BufWinEnter', {
        pattern = '*/diary/*.md',
        callback = function()
          -- 1. Only proceed if the buffer is totally empty
          if vim.fn.line '$' == 1 and vim.fn.getline(1) == '' then
            local current_file = vim.fn.expand '%:p'
            local script_path = vim.fn.expand '~/Documents/Notes/vimwiki/diary/vimwiki-diary-tpl.py'

            -- 2. Construct and run the command
            local cmd = string.format('0r! python3 %s %s', script_path, vim.fn.shellescape(current_file))
            vim.cmd(cmd)

            -- 3. Delete the trailing empty line created by '0r'
            vim.cmd '$d'

            -- 4. Tell Taskwiki to scan the new headers immediately
            vim.defer_fn(function()
              if vim.fn.exists ':TaskWikiBufferRTOn' > 0 then vim.cmd 'TaskWikiBufferRTOn' end
            end, 100) -- Small delay to let the text settle
          end
        end,
      })
    end,
  },
}
