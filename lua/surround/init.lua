local M = {}

local function get_pair(char)
  local pairs_map = {
    ["("] = { "(", ")", },
    [")"] = { "(", ")", },
    ["["] = { "[", "]", },
    ["]"] = { "[", "]", },
    ["{"] = { "{", "}", },
    ["}"] = { "{", "}", },
    ["<"] = { "<", ">", },
    [">"] = { "<", ">", },
    ["'"] = { "'", "'", },
    ['"'] = { '"', '"', },
    ["`"] = { "`", "`", },
    [" "] = { " ", " ", },
  }
  local pair = pairs_map[char]
  if not pair then return nil end
  return { open = pair[1], close = pair[2], }
end

--- @param level vim.log.levels
--- @param msg string
--- @param ... any
local notify = function(level, msg, ...)
  msg = "[surround.nvim]: " .. msg
  vim.notify(msg:format(...), level)
end

--- @param start_mark string
--- @param end_mark string
local function get_pos_from_marks(start_mark, end_mark)
  local open_pos = vim.api.nvim_buf_get_mark(0, start_mark)
  if open_pos[1] == 0 and open_pos[2] == 0 then return nil end

  local close_pos = vim.api.nvim_buf_get_mark(0, end_mark)
  if close_pos[1] == 0 and close_pos[2] == 0 then return nil end

  if open_pos[1] == close_pos[1] and open_pos[2] == close_pos[2] then return nil end

  return {
    open_row_0i = open_pos[1] - 1,
    open_row_1i = open_pos[1],
    open_col_0i = open_pos[2],
    open_col_1i = open_pos[2] + 1,
    close_row_0i = close_pos[1] - 1,
    close_row_1i = close_pos[1],
    close_col_0i = close_pos[2],
    close_col_1i = close_pos[2] + 1,
  }
end

--- @param row number
--- @param col number
local function clamp_to_line_len(row, col)
  local one_idx_offset = 1
  local line_text = vim.api.nvim_buf_get_lines(0, row, row + 1, true)[1]
  return math.min(col, #line_text - one_idx_offset)
end

--- adjusts for whitespace that `va` may include for quote text objects.
--- @param char string
--- @return table|nil
local function find_surround_pos(char)
  local saved_visual_hl = vim.api.nvim_get_hl(0, { name = "Visual", })
  local saved_cursor = vim.api.nvim_win_get_cursor(0)

  vim.api.nvim_set_hl(0, "Visual", { link = "Normal", })
  vim.cmd("normal! va" .. char)
  vim.cmd "normal! \x1b"
  vim.api.nvim_set_hl(0, "Visual", saved_visual_hl)
  vim.api.nvim_win_set_cursor(0, saved_cursor)

  local pos = get_pos_from_marks("<", ">")
  if pos == nil then return nil end

  local pair = get_pair(char)
  if pair == nil then return nil end

  local open_line = vim.api.nvim_buf_get_lines(0, pos.open_row_0i, pos.open_row_0i + 1, true)[1]
  if open_line:sub(pos.open_col_1i, pos.open_col_1i) ~= pair.open then
    for i = pos.open_col_1i + 1, #open_line do
      if open_line:sub(i, i) == pair.open then
        pos.open_col_0i = i - 1
        pos.open_col_1i = i
        break
      end
    end
  end

  local close_line = vim.api.nvim_buf_get_lines(0, pos.close_row_0i, pos.close_row_0i + 1, true)[1]
  if close_line:sub(pos.close_col_1i, pos.close_col_1i) ~= pair.close then
    for i = pos.close_col_0i, 1, -1 do
      if close_line:sub(i, i) == pair.close then
        pos.close_col_0i = i - 1
        pos.close_col_1i = i
        break
      end
    end
  end

  return pos
end


M.setup = function()
  vim.keymap.set("n", "ds", function()
    local char = vim.fn.nr2char(vim.fn.getchar())

    _G.__surround_delete = function()
      local pair_pos = find_surround_pos(char)

      if pair_pos == nil then
        notify(vim.log.levels.ERROR, "No matching pair")
        return
      end

      vim.api.nvim_buf_set_text(0,
        pair_pos.close_row_0i, pair_pos.close_col_0i, pair_pos.close_row_0i, pair_pos.close_col_0i + 1,
        { "", }
      )
      vim.api.nvim_buf_set_text(0,
        pair_pos.open_row_0i, pair_pos.open_col_0i, pair_pos.open_row_0i, pair_pos.open_col_0i + 1,
        { "", }
      )
    end

    vim.o.operatorfunc = "v:lua.__surround_delete"
    return "g@l"
  end, { expr = true, })

  vim.keymap.set("n", "cs", function()
    local old_char = vim.fn.nr2char(vim.fn.getchar())
    local new_pair_cached = nil

    _G.__surround_change = function()
      if new_pair_cached == nil then
        local new_char = vim.fn.nr2char(vim.fn.getchar())

        new_pair_cached = get_pair(new_char)
        if new_pair_cached == nil then
          notify(vim.log.levels.ERROR, "Invalid pair")
          return
        end
      end

      local old_pair_pos = find_surround_pos(old_char)

      if old_pair_pos == nil then
        notify(vim.log.levels.ERROR, "No matching pair")
        return
      end

      vim.api.nvim_buf_set_text(0,
        old_pair_pos.close_row_0i, old_pair_pos.close_col_0i, old_pair_pos.close_row_0i, old_pair_pos.close_col_0i + 1,
        { new_pair_cached.close, }
      )
      vim.api.nvim_buf_set_text(0,
        old_pair_pos.open_row_0i, old_pair_pos.open_col_0i, old_pair_pos.open_row_0i, old_pair_pos.open_col_0i + 1,
        { new_pair_cached.open, }
      )
    end

    vim.o.operatorfunc = "v:lua.__surround_change"
    return "g@l"
  end, { expr = true, })

  vim.keymap.set("n", "ys", function()
    local pair_cached = nil

    _G.__surround_add = function()
      if pair_cached == nil then
        local surround_char = vim.fn.nr2char(vim.fn.getchar())
        pair_cached = get_pair(surround_char)
        if pair_cached == nil then
          notify(vim.log.levels.ERROR, "Invalid pair")
          return
        end
      end

      local pos = get_pos_from_marks("[", "]")
      assert(pos ~= nil)
      pos.close_col_0i = clamp_to_line_len(pos.close_row_0i, pos.close_col_0i)

      vim.api.nvim_buf_set_text(0, pos.close_row_0i, pos.close_col_0i + 1, pos.close_row_0i, pos.close_col_0i + 1,
        { pair_cached.close, })
      vim.api.nvim_buf_set_text(0, pos.open_row_0i, pos.open_col_0i, pos.open_row_0i, pos.open_col_0i,
        { pair_cached.open, })
    end

    vim.o.operatorfunc = "v:lua.__surround_add"
    return "g@"
  end, { expr = true, })

  vim.keymap.set("v", "S", function()
    local surround_char = vim.fn.nr2char(vim.fn.getchar())
    local pair = get_pair(surround_char)
    if pair == nil then
      notify(vim.log.levels.ERROR, "Invalid pair")
      return
    end

    vim.cmd "normal! \x1b"
    local pos = get_pos_from_marks("<", ">")
    assert(pos ~= nil)
    pos.close_col_0i = clamp_to_line_len(pos.close_row_0i, pos.close_col_0i)

    vim.api.nvim_buf_set_text(0, pos.close_row_0i, pos.close_col_0i + 1, pos.close_row_0i, pos.close_col_0i + 1,
      { pair.close, })
    vim.api.nvim_buf_set_text(0, pos.open_row_0i, pos.open_col_0i, pos.open_row_0i, pos.open_col_0i, { pair.open, })
  end)
end

return M
