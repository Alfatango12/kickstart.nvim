return {
  'bngarren/checkmate.nvim',
  ft = { 'markdown', 'todo' },

  -- Removed `<leader>Tt` from here so Checkmate doesn't hijack it
  keys = {
    { '<leader>Tc', '<cmd>Checkmate check<CR>', desc = 'Set todo item as checked', mode = { 'n', 'v' } },
    { '<leader>Tu', '<cmd>Checkmate uncheck<CR>', desc = 'Set todo item as unchecked', mode = { 'n', 'v' } },
    { '<leader>T=', '<cmd>Checkmate cycle_next<CR>', desc = 'Cycle next state', mode = { 'n', 'v' } },
    { '<leader>T-', '<cmd>Checkmate cycle_previous<CR>', desc = 'Cycle previous state', mode = { 'n', 'v' } },
    { '<leader>Tn', '<cmd>Checkmate create<CR>', desc = 'Create todo item', mode = { 'n', 'v' } },
    { '<leader>Tr', '<cmd>Checkmate remove<CR>', desc = 'Remove todo marker', mode = { 'n', 'v' } },
    { '<leader>TR', '<cmd>Checkmate remove_all_metadata<CR>', desc = 'Remove all metadata', mode = { 'n', 'v' } },
    { '<leader>Ta', '<cmd>Checkmate archive<CR>', desc = 'Archive checked items', mode = { 'n' } },
    { '<leader>TF', '<cmd>Checkmate select_todo<CR>', desc = 'Select todo picker', mode = { 'n' } },
    { '<leader>Tv', '<cmd>Checkmate metadata select_value<CR>', desc = 'Update metadata value', mode = { 'n' } },
    { '<leader>T]', '<cmd>Checkmate metadata jump_next<CR>', desc = 'Next metadata tag', mode = { 'n' } },
    { '<leader>T[', '<cmd>Checkmate metadata jump_previous<CR>', desc = 'Previous metadata tag', mode = { 'n' } },
  },

  init = function()
    vim.filetype.add {
      extension = { todo = 'markdown' },
      filename = { ['TODO'] = 'markdown', ['todo'] = 'markdown' },
    }
  end,

  -- Ensure your custom mapping takes precedence by placing it in config
  config = function(_, opts)
    require('checkmate').setup(opts)

    vim.keymap.set('n', '<leader>Tt', function()
      local ok, sync = pcall(require, 'util.todo_sync')
      if ok then
        sync.sync_toggle()
      else
        vim.cmd 'Checkmate toggle'
      end
    end, { desc = 'Smart Toggle (Local + Source Sync)', buffer = false })
  end,

  opts = {
    enabled = true,
    notify = true,
    files = { '*.md' },
    log = { level = 'warn', use_file = true },
    default_list_marker = '-',
    todo_states = {
      unchecked = { marker = '□', order = 1 },
      checked = { marker = '✔', order = 2 },
    },
    enter_insert_after_new = true,
    list_continuation = {
      enabled = true,
      split_line = true,
      keys = {
        ['<CR>'] = function() require('checkmate').create { position = 'below', indent = false } end,
        ['<S-CR>'] = function() require('checkmate').create { position = 'below', indent = true } end,
      },
    },
    smart_toggle = {
      enabled = true,
      include_cycle = false,
      check_down = 'direct_children',
      uncheck_down = 'none',
      check_up = 'direct_children',
      uncheck_up = 'direct_children',
    },
    show_todo_count = true,
    todo_count_position = 'eol',
    todo_count_recursive = true,
    use_metadata_keymaps = true,
    metadata = {
      priority = {
        style = function(context)
          local value = context.value:lower()
          if value == 'high' then
            return { fg = '#ff5555', bold = true }
          elseif value == 'medium' then
            return { fg = '#ffb86c' }
          else
            return { fg = '#8be9fd' }
          end
        end,
        get_value = function() return 'medium' end,
        choices = function() return { 'low', 'medium', 'high' } end,
        key = '<leader>Tp',
        sort_order = 10,
        jump_to_on_insert = 'value',
        select_on_insert = true,
      },
      started = {
        aliases = { 'init' },
        style = { fg = '#9fd6d5' },
        get_value = function() return tostring(os.date '%m/%d/%y %H:%M') end,
        key = '<leader>Ts',
        sort_order = 20,
      },
      done = {
        aliases = { 'completed', 'finished' },
        style = { fg = '#96de7a' },
        get_value = function() return tostring(os.date '%m/%d/%y %H:%M') end,
        key = '<leader>TD',
        on_add = function(todo) require('checkmate').set_todo_state(todo, 'checked') end,
        on_remove = function(todo) require('checkmate').set_todo_state(todo, 'unchecked') end,
        sort_order = 30,
      },
      due = {
        get_value = function()
          local t = os.date '*t'
          t.day = t.day + 1
          return os.date('%d/%m/%y', os.time(t))
        end,
        key = '<leader>Td',
        style = { fg = '#96de7a' },
        jump_to_on_insert = 'value',
        select_on_insert = true,
      },
      project = {
        get_value = function() return 'none' end,
        style = { fg = '#96de7a' },
        key = '<leader>TP',
        jump_to_on_insert = 'value',
        select_on_insert = true,
      },
      link = {
        get_value = function() return 'none' end,
        style = { fg = '#96de7a' },
        key = '<leader>Tl',
        jump_to_on_insert = 'value',
        select_on_insert = true,
      },
    },
    archive = {
      heading = { title = 'Archive', level = 2 },
      parent_spacing = 0,
      newest_first = true,
    },
    linter = { enabled = true },
  },
}
