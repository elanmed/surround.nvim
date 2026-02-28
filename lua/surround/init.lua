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

--- @param char string
local function trigger_visual(char)
  local saved_visual_hl = vim.api.nvim_get_hl(0, { name = "Visual", })
  local saved_cursor = vim.api.nvim_win_get_cursor(0)

  vim.api.nvim_set_hl(0, "Visual", { link = "Normal", })
  vim.cmd("normal! va" .. char)
  vim.cmd "normal! \x1b"
  vim.api.nvim_set_hl(0, "Visual", saved_visual_hl)
  vim.api.nvim_win_set_cursor(0, saved_cursor)
end

--- @param start_mark string
--- @param end_mark string
local function get_pos_from_marks_0i(start_mark, end_mark)
  local open_pos = vim.api.nvim_buf_get_mark(0, start_mark)
  if open_pos[1] == 0 and open_pos[2] == 0 then return nil end

  local close_pos = vim.api.nvim_buf_get_mark(0, end_mark)
  if close_pos[1] == 0 and close_pos[2] == 0 then return nil end

  if open_pos[1] == close_pos[1] and open_pos[2] == close_pos[2] then return nil end

  local one_idx_offset = 1

  return {
    open_row = open_pos[1] - one_idx_offset,
    open_col = open_pos[2],
    close_row = close_pos[1] - one_idx_offset,
    close_col = close_pos[2],
  }
end

--- @param row number
--- @param col number
local function clamp_to_line_len(row, col)
  local one_idx_offset = 1
  local line_text = vim.api.nvim_buf_get_lines(0, row, row + 1, true)[1]
  return math.min(col, #line_text - one_idx_offset)
end


M.setup = function()
  vim.keymap.set("n", "ds", function()
    local char = vim.fn.nr2char(vim.fn.getchar())

    trigger_visual(char)
    local pair_pos = get_pos_from_marks_0i("<", ">")

    if pair_pos == nil then
      notify(vim.log.levels.ERROR, "No matching pair")
      return
    end

    vim.api.nvim_buf_set_text(0,
      pair_pos.close_row, pair_pos.close_col, pair_pos.close_row, pair_pos.close_col + 1,
      { "", }
    )
    vim.api.nvim_buf_set_text(0,
      pair_pos.open_row, pair_pos.open_col, pair_pos.open_row, pair_pos.open_col + 1,
      { "", }
    )
  end)

  vim.keymap.set("n", "cs", function()
    local old_char = vim.fn.nr2char(vim.fn.getchar())
    local new_char = vim.fn.nr2char(vim.fn.getchar())

    trigger_visual(old_char)
    local old_pair_pos = get_pos_from_marks_0i("<", ">")

    if old_pair_pos == nil then
      notify(vim.log.levels.ERROR, "No matching pair")
      return
    end

    local new_pair = get_pair(new_char)
    if new_pair == nil then
      notify(vim.log.levels.ERROR, "Invalid pair")
      return
    end

    vim.api.nvim_buf_set_text(0,
      old_pair_pos.close_row, old_pair_pos.close_col, old_pair_pos.close_row, old_pair_pos.close_col + 1,
      { new_pair.close, }
    )
    vim.api.nvim_buf_set_text(0,
      old_pair_pos.open_row, old_pair_pos.open_col, old_pair_pos.open_row, old_pair_pos.open_col + 1,
      { new_pair.open, }
    )
  end)

  vim.keymap.set("n", "ys", function()
    _G.__surround_add = function()
      local surround_char = vim.fn.nr2char(vim.fn.getchar())
      local pair = get_pair(surround_char)
      if pair == nil then
        notify(vim.log.levels.ERROR, "Invalid pair")
        return
      end

      local pos = get_pos_from_marks_0i("[", "]")
      assert(pos ~= nil)
      pos.close_col = clamp_to_line_len(pos.close_row, pos.close_col)

      vim.api.nvim_buf_set_text(0, pos.close_row, pos.close_col + 1, pos.close_row, pos.close_col + 1, { pair.close, })
      vim.api.nvim_buf_set_text(0, pos.open_row, pos.open_col, pos.open_row, pos.open_col, { pair.open, })
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
    local pos = get_pos_from_marks_0i("<", ">")
    assert(pos ~= nil)
    pos.close_col = clamp_to_line_len(pos.close_row, pos.close_col)

    vim.api.nvim_buf_set_text(0, pos.close_row, pos.close_col + 1, pos.close_row, pos.close_col + 1, { pair.close, })
    vim.api.nvim_buf_set_text(0, pos.open_row, pos.open_col, pos.open_row, pos.open_col, { pair.open, })
  end)
end

return M
