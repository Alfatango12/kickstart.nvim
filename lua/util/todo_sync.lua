local M = {}

-- CONFIGURATION
local UNCHECKED = '□'
local CHECKED = '✔'
local MONOLITH_NAME = '202603291443-todo'
local MONOLITH_FILE = MONOLITH_NAME .. '.md'
local VAULT_PATH = vim.fn.expand '~/Documents/Notes/masterVault/'
local MONOLITH_FULL_PATH = VAULT_PATH .. MONOLITH_FILE

local function escape_lua_pattern(s) return (s:gsub('[%^%$%(%)%%%.%[%]%*%+%-%?]', '%%%1')) end

local function read_file(path)
  local f = io.open(path, 'r')
  if not f then return nil end
  local lines = {}
  for line in f:lines() do
    table.insert(lines, line)
  end
  f:close()
  return lines
end

local function write_file(path, lines)
  local f = io.open(path, 'w')
  if not f then return false end
  for _, line in ipairs(lines) do
    f:write(line .. '\n')
  end
  f:close()
  return true
end

local function get_buf_by_name(filename)
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    local name = vim.api.nvim_buf_get_name(buf)
    if name:match(escape_lua_pattern(filename) .. '$') then return buf end
  end
  return nil
end

local function get_hash(str) return vim.fn.sha256(str):sub(1, 8) end

-- Push changes FROM the Daily Note TO the Monolith
function M.sync_to_monolith()
  local buf = vim.api.nvim_get_current_buf()
  local path = vim.api.nvim_buf_get_name(buf)
  local filename = vim.fn.fnamemodify(path, ':t')

  if filename == MONOLITH_FILE then return end
  if not filename:match '^%d%d%d%d%-%d%d%-%d%d' then return end

  local buf_lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

  local mono_buf = get_buf_by_name(MONOLITH_FILE)
  local monolith_lines = nil
  if mono_buf and vim.api.nvim_buf_is_loaded(mono_buf) then
    monolith_lines = vim.api.nvim_buf_get_lines(mono_buf, 0, -1, false)
  else
    monolith_lines = read_file(MONOLITH_FULL_PATH)
  end

  if not monolith_lines then return end

  local monolith_updated = false
  local base_source_tag = ' %(from %[%[' .. escape_lua_pattern(MONOLITH_NAME) .. '%]%]%)'

  -- Scan daily note for synced tasks with a hidden ID
  for row_idx, line in ipairs(buf_lines) do
    local id_match = line:match '<!%-%-id:([a-f0-9]+)%-%->'

    if id_match then
      -- Reconstruct what the monolith line *should* look like now
      -- by stripping the source tag and the hidden HTML comment
      local clean_line = line:gsub(base_source_tag .. ' %<!%-%-id:[a-f0-9]+%-%->%s*$', '')

      -- Find the original line in the monolith by hashing
      for i, m_line in ipairs(monolith_lines) do
        if get_hash(m_line) == id_match then
          if m_line ~= clean_line then
            monolith_lines[i] = clean_line
            monolith_updated = true

            -- Update the ID in the daily note so we can keep editing without breaking the link
            local new_hash = get_hash(clean_line)
            local updated_daily_line = clean_line .. ' (from [[' .. MONOLITH_NAME .. ']]) <!--id:' .. new_hash .. '-->'
            vim.api.nvim_buf_set_lines(buf, row_idx - 1, row_idx, false, { updated_daily_line })
          end
          break
        end
      end
    end
  end

  if monolith_updated then
    if mono_buf and vim.api.nvim_buf_is_loaded(mono_buf) then
      vim.api.nvim_buf_set_lines(mono_buf, 0, -1, false, monolith_lines)
      vim.api.nvim_buf_call(mono_buf, function() vim.cmd 'silent! write' end)
    else
      write_file(MONOLITH_FULL_PATH, monolith_lines)
    end
  end
end

-- Pull changes FROM the Monolith TO the Daily Note
function M.refresh_daily_tasks()
  vim.schedule(function()
    local buf = vim.api.nvim_get_current_buf()
    local path = vim.api.nvim_buf_get_name(buf)
    local filename = vim.fn.fnamemodify(path, ':t')

    if filename == MONOLITH_FILE then return end

    local year, month, day = filename:match '(%d%d%d%d)%-(%d%d)%-(%d%d)'
    if not (year and month and day) then return end

    local date_str = string.format('%s/%s/%s', day, month, year:sub(3, 4))
    local due_tag = '@due(' .. date_str .. ')'

    -- Read monolith
    local mono_buf = get_buf_by_name(MONOLITH_FILE)
    local monolith_lines = nil
    if mono_buf and vim.api.nvim_buf_is_loaded(mono_buf) then
      monolith_lines = vim.api.nvim_buf_get_lines(mono_buf, 0, -1, false)
    else
      monolith_lines = read_file(MONOLITH_FULL_PATH)
    end

    if not monolith_lines then return end

    local daily_tasks = {}
    for _, line in ipairs(monolith_lines) do
      if line:find(due_tag, 1, true) and line:find('^%s*[-*]%s+[' .. UNCHECKED .. CHECKED .. ']') then
        -- Generate a hash of the original monolith line to track edits
        local hash = get_hash(line)
        local source_tag = ' (from [[' .. MONOLITH_NAME .. ']]) <!--id:' .. hash .. '-->'
        table.insert(daily_tasks, vim.trim(line) .. source_tag)
      end
    end

    local buf_lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local new_buf_lines = {}
    local frontmatter_end = 0
    local skip_mode = false
    local base_source_tag = ' (from [[' .. MONOLITH_NAME .. ']])'

    for i, line in ipairs(buf_lines) do
      if line == '---' and i > 1 and frontmatter_end == 0 then
        frontmatter_end = i
        table.insert(new_buf_lines, line)
      elseif line:find('## Tasks Due Today', 1, true) then
        skip_mode = true
      elseif skip_mode and line == '' then
      elseif skip_mode and line:find(base_source_tag, 1, true) then
      elseif skip_mode and not line:find '^%s*[-*]' and line ~= '' then
        skip_mode = false
        table.insert(new_buf_lines, line)
      elseif not skip_mode then
        table.insert(new_buf_lines, line)
      end
    end

    if #daily_tasks > 0 then
      local insert_idx = frontmatter_end > 0 and (frontmatter_end + 1) or 1
      local tasks_to_insert = { '', '## Tasks Due Today (' .. date_str .. ')' }
      for _, task in ipairs(daily_tasks) do
        table.insert(tasks_to_insert, task)
      end
      table.insert(tasks_to_insert, '')

      for i = #tasks_to_insert, 1, -1 do
        table.insert(new_buf_lines, insert_idx, tasks_to_insert[i])
      end
    end

    vim.api.nvim_buf_set_lines(buf, 0, -1, false, new_buf_lines)
  end)
end

function M.sync_toggle()
  -- Using standard Checkmate toggle first to handle UI
  vim.cmd 'Checkmate toggle'

  -- If we're in the daily note, immediately sync back to the monolith
  local buf = vim.api.nvim_get_current_buf()
  local path = vim.api.nvim_buf_get_name(buf)
  local filename = vim.fn.fnamemodify(path, ':t')

  if filename ~= MONOLITH_FILE and filename:match '^%d%d%d%d%-%d%d%-%d%d' then M.sync_to_monolith() end

  -- Autosave the current buffer
  vim.cmd 'silent! write'
end

return M
