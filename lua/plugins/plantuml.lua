return {
  'Maduki-tech/nvim-plantuml',
  ft = { 'plantuml', 'puml' },
  config = function()
    require('plantuml').setup {
      output_dir = '/tmp',
      view = 'open',
      viewer = 'open',
      auto_refresh = true,
    }

    local puml_pane_id = nil

    vim.api.nvim_create_user_command('PlantUMLPreview', function()
      local file = vim.fn.expand '%:p'
      local output_dir = '/tmp'

      vim.fn.jobstart({ 'plantuml', '-o', output_dir, file }, {
        on_exit = function()
          local name_guess = output_dir .. '/' .. vim.fn.expand '%:t:r' .. '.png'
          local fallback = output_dir .. '/diagram.png'
          local target = (vim.fn.filereadable(name_guess) == 1) and name_guess or fallback

          if vim.fn.filereadable(target) == 1 then
            local pane_exists = false
            if puml_pane_id then
              local check = os.execute('tmux has-session -t ' .. puml_pane_id .. ' 2>/dev/null')
              pane_exists = (check == 0)
            end

            if pane_exists then
              local update_cmd = string.format('tmux send-keys -t %s C-u \'clear; chafa "%s"\' Enter', puml_pane_id, target)
              os.execute(update_cmd)
            else
              local cmd = string.format "tmux split-window -h -P -F '#{pane_id}' 'sh'"
              local handle = io.popen(cmd)
              puml_pane_id = handle:read('*a'):gsub('%s+', '')
              handle:close()

              local first_load = string.format('tmux send-keys -t %s \'clear; chafa "%s"\' Enter', puml_pane_id, target)
              os.execute(first_load)
            end
          end
        end,
      })
    end, {})

    -- 1. Refresh on Save
    vim.api.nvim_create_autocmd('BufWritePost', {
      pattern = { '*.puml', '*.plantuml' },
      callback = function() vim.cmd 'PlantUMLPreview' end,
    })

    -- 2. Cleanup on Exit
    vim.api.nvim_create_autocmd('VimLeave', {
      callback = function()
        if puml_pane_id then os.execute('tmux kill-pane -t ' .. puml_pane_id .. ' 2>/dev/null') end
      end,
    })
  end,
}
