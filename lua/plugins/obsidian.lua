return {
  'obsidian-nvim/obsidian.nvim',
  version = '*', -- recommended, use latest release instead of latest commit
  lazy = true,
  ft = 'markdown',
  cmd = {
    --[[ 'Obsidian new',
    'Obsidian search',
    'ObsidianQuickSwitch',
    'ObsidianToday',
    'ObsidianDailies',
    'ObsidianTemplate',
    'ObsidianRename', ]]
    'Obsidian',
  },
  opts = {
    -- 1. Essential workspace setup
    workspaces = {
      {
        name = 'master',
        path = '~/Documents/Notes/masterVault/',
      },
    },

    -- 2. DISABLE legacy commands to stop the warning
    -- Note: This means you should now use ':Obsidian backlinks' (with a space)
    -- instead of ':ObsidianBacklinks' (CamelCase)
    legacy_commands = false,

    -- 3. MODERN Link configuration
    links = {
      -- This replaces 'preferred_link_style'
      style = 'wiki',
    },

    -- 4. Filename logic (remains the same)
    note_id_func = function(title)
      local prefix = os.date '%Y%m%d%H%M'
      if title ~= nil then
        local cleaned = title:gsub(' ', '-'):gsub('[^A-Za-z0-9-]', ''):lower()
        return prefix .. '-' .. cleaned
      else
        return tostring(prefix)
      end
    end,

    -- 5. YAML Metadata (remains the same)
    frontmatter_creator = function(note)
      local out = { id = note.id, title = note.title, tags = note.tags }
      if note.metadata ~= nil and not vim.tbl_isempty(note.metadata) then
        for k, v in pairs(note.metadata) do
          out[k] = v
        end
      end
      return out
    end,
  },
  keys = {
    -- 1. Open the main index
    {
      '<leader>oi',
      function() vim.cmd 'edit ~/Documents/Notes/masterVault/*index.md' end,
      desc = 'Open Obsidian Index',
    },
    -- 2. Search for notes
    {
      '<leader>os',
      '<cmd>Obsidian search<cr>',
      desc = 'Search Obsidian Notes',
    },
    -- 3. Create a new note
    {
      '<leader>on',
      function()
        local title = vim.fn.input 'Note Title: '
        if title ~= '' then vim.cmd('Obsidian new ' .. title) end
      end,
      desc = 'New Obsidian Note',
    },
    -- 4. Follow Link (The new mapping)
    {
      '<leader>of',
      '<cmd>Obsidian link<CR>',
      desc = 'Follow Obsidian Link',
    },
    {
      '<leader>ot', -- "Obsidian Today" refresh
      function() require('util.todo_sync').refresh_daily_tasks() end,
      desc = 'Refresh Daily Tasks',
    },
  },
}
