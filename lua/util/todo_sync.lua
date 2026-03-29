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

-- Push changes FROM the Note (Daily or Project) TO the Monolith
function M.sync_to_monolith()
  local buf = vim.api.nvim_get_current_buf()
  local path = vim.api.nvim_buf_get_name(buf)
  local filename = vim.fn.fnamemodify(path, ':t')

  if filename == MONOLITH_FILE then return end

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

  -- Scan note for synced tasks with a hidden ID
  for row_idx, line in ipairs(buf_lines) do
    local id_match = line:match '<!%-%-id:([a-f0-9]+)%-%->'

    if id_match then
      -- Reconstruct what the monolith line *should* look like now
      local clean_line = line:gsub(base_source_tag .. ' %<!%-%-id:[a-f0-9]+%-%->%s*$', '')
      clean_line = clean_line:gsub(' %<!%-%-id:[a-f0-9]+%-%->%s*$', '') -- fallback (for new version)

      -- Find the original line in the monolith by hashing
      for i, m_line in ipairs(monolith_lines) do
        if get_hash(m_line) == id_match then
          if m_line ~= clean_line then
            monolith_lines[i] = clean_line
            monolith_updated = true

            -- Update the ID in the note so we can keep editing without breaking the link
            local new_hash = get_hash(clean_line)
            local updated_daily_line = clean_line .. ' <!--id:' .. new_hash .. '-->'
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

-- Pull changes FROM the Monolith TO the Note (Daily or Project)
function M.refresh_tasks()
  vim.schedule(function()
    local buf = vim.api.nvim_get_current_buf()
    local path = vim.api.nvim_buf_get_name(buf)
    local filename = vim.fn.fnamemodify(path, ':t')

    if filename == MONOLITH_FILE then return end

    local buf_lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

    -- Feature 1: Check if it's a Daily Note based on filename
    local is_daily = false
    local date_str, due_tag
    local year, month, day = filename:match '^(%d%d%d%d)%-(%d%d)%-(%d%d)'
    if year and month and day then
      is_daily = true
      date_str = string.format('%s/%s/%s', day, month, year:sub(3, 4))
      due_tag = '@due(' .. date_str .. ')'
    end

    -- Feature 2: Check if it's a Project Note based on frontmatter
    local project_name = nil
    local frontmatter_end = 0
    if buf_lines[1] == '---' then
      for i = 2, #buf_lines do
        if buf_lines[i] == '---' then
          frontmatter_end = i
          break
        end
        local parsed_proj = buf_lines[i]:match '^project:%s*(.-)%s*$'
        if parsed_proj then project_name = parsed_proj end
      end
    end

    -- If neither a daily note nor a project note, do nothing
    if not is_daily and not project_name then return end

    -- Read monolith
    local mono_buf = get_buf_by_name(MONOLITH_FILE)
    local monolith_lines = nil
    if mono_buf and vim.api.nvim_buf_is_loaded(mono_buf) then
      monolith_lines = vim.api.nvim_buf_get_lines(mono_buf, 0, -1, false)
    else
      monolith_lines = read_file(MONOLITH_FULL_PATH)
    end

    if not monolith_lines then return end

    -- Collect relevant tasks (preserve original indentation)
    local daily_tasks = {}
    local project_tasks = {}

    for _, line in ipairs(monolith_lines) do
      if line:find('^%s*[-*]%s+[' .. UNCHECKED .. CHECKED .. ']') then
        local hash = get_hash(line)
        local source_tag = ' <!--id:' .. hash .. '-->'

        -- Match Date tasks
        if is_daily and line:find(due_tag, 1, true) then table.insert(daily_tasks, line .. source_tag) end

        -- Match Project tasks
        if project_name and line:find('@project(' .. project_name .. ')', 1, true) then table.insert(project_tasks, line .. source_tag) end
      end
    end

    -- Rebuild buffer lines (filtering out old injected sections)
    local new_buf_lines = {}
    local skip_mode = false
    local base_source_tag = ' <!--id:'

    for i, line in ipairs(buf_lines) do
      if i <= frontmatter_end and frontmatter_end > 0 then
        table.insert(new_buf_lines, line)
      elseif line:find('## Tasks Due Today', 1, true) or line:find('## Tasks for Project', 1, true) then
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

    -- Inject sections right below frontmatter
    local insert_idx = frontmatter_end > 0 and (frontmatter_end + 1) or 1
    local blocks_to_insert = {}

    -- Prepare Daily block if any
    if #daily_tasks > 0 then
      table.insert(blocks_to_insert, '')
      table.insert(blocks_to_insert, '## Tasks Due Today (' .. date_str .. ')')
      for _, task in ipairs(daily_tasks) do
        table.insert(blocks_to_insert, task)
      end
    end

    -- Prepare Project block if any
    if #project_tasks > 0 then
      table.insert(blocks_to_insert, '')
      table.insert(blocks_to_insert, '## Tasks for Project: ' .. project_name)
      for _, task in ipairs(project_tasks) do
        table.insert(blocks_to_insert, task)
      end
    end

    -- Insert blocks
    if #blocks_to_insert > 0 then
      table.insert(blocks_to_insert, '') -- Trailing space
      for i = #blocks_to_insert, 1, -1 do
        table.insert(new_buf_lines, insert_idx, blocks_to_insert[i])
      end
    end

    vim.api.nvim_buf_set_lines(buf, 0, -1, false, new_buf_lines)
  end)
end

function M.sync_toggle()
  vim.cmd 'Checkmate toggle'

  local buf = vim.api.nvim_get_current_buf()
  local path = vim.api.nvim_buf_get_name(buf)
  local filename = vim.fn.fnamemodify(path, ':t')

  if filename ~= MONOLITH_FILE then M.sync_to_monolith() end

  vim.cmd 'silent! write'
end

return M
