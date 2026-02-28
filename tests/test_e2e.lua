local new_set = MiniTest.new_set
local expect, eq = MiniTest.expect, MiniTest.expect.equality

local child = MiniTest.new_child_neovim()

local T = new_set {
  hooks = {
    pre_case = function()
      child.restart { "-u", "scripts/minimal_init.lua", }
      child.bo.readonly = false
      child.lua [[require("surround").setup()]]
    end,
    post_once = child.stop,
  },
}

local set_lines = function(lines) child.api.nvim_buf_set_lines(0, 0, -1, true, lines) end
local set_cursor = function(row, col) child.api.nvim_win_set_cursor(0, { row, col, }) end

local expect_lines = MiniTest.new_expectation(
  "buffer lines",
  function(expected)
    local actual = child.api.nvim_buf_get_lines(0, 0, -1, true)
    return vim.deep_equal(actual, expected)
  end,
  function(expected)
    local actual = child.api.nvim_buf_get_lines(0, 0, -1, true)
    return string.format("Expected: %s\nActual: %s", vim.inspect(expected), vim.inspect(actual))
  end
)

local expect_cursor = MiniTest.new_expectation(
  "cursor position",
  function(row, col)
    local actual = child.api.nvim_win_get_cursor(0)
    return actual[1] == row and actual[2] == col
  end,
  function(row, col)
    local actual = child.api.nvim_win_get_cursor(0)
    return string.format("Expected: {%d, %d}\nActual: {%d, %d}", row, col, actual[1], actual[2])
  end
)

local stub_notify = function()
  child.lua [[
    _G.notify_log = {}
    vim.notify = function(msg, level)
      table.insert(_G.notify_log, { msg = msg, level = level, })
    end
  ]]
end

local expect_notify = MiniTest.new_expectation(
  "notification",
  function(expected_msg, expected_level)
    local log = child.lua_get [[_G.notify_log]]
    if #log ~= 1 then return false end
    return log[1].msg == expected_msg and log[1].level == expected_level
  end,
  function(expected_msg, expected_level)
    local log = child.lua_get [[_G.notify_log]]
    return string.format(
      "Expected: 1 notification with msg=%s, level=%d\nActual: %s",
      vim.inspect(expected_msg), expected_level, vim.inspect(log)
    )
  end
)

T["ds"] = new_set()

T["ds"]["deletes surrounding parentheses"] = function()
  set_lines { "(hello)", }
  set_cursor(1, 1)
  child.type_keys("ds", ")")
  expect_lines { "hello", }
  expect_cursor(1, 0)
end

T["ds"]["deletes surrounding brackets"] = function()
  set_lines { "[hello]", }
  set_cursor(1, 1)
  child.type_keys("ds", "]")
  expect_lines { "hello", }
  expect_cursor(1, 0)
end

T["ds"]["deletes surrounding braces"] = function()
  set_lines { "{hello}", }
  set_cursor(1, 1)
  child.type_keys("ds", "}")
  expect_lines { "hello", }
  expect_cursor(1, 0)
end

T["ds"]["deletes surrounding angle brackets"] = function()
  set_lines { "<hello>", }
  set_cursor(1, 1)
  child.type_keys("ds", ">")
  expect_lines { "hello", }
  expect_cursor(1, 0)
end

T["ds"]["deletes surrounding quotes"] = function()
  set_lines { '"hello"', }
  set_cursor(1, 1)
  child.type_keys("ds", '"')
  expect_lines { "hello", }
  expect_cursor(1, 0)
end

T["ds"]["deletes surrounding single quotes"] = function()
  set_lines { "'hello'", }
  set_cursor(1, 2)
  child.type_keys("ds", "'")
  expect_lines { "hello", }
  expect_cursor(1, 1)
end

T["ds"]["deletes surrounding backticks"] = function()
  set_lines { "`hello`", }
  set_cursor(1, 1)
  child.type_keys("ds", "`")
  expect_lines { "hello", }
  expect_cursor(1, 0)
end

T["ds"]["works with nested pairs"] = function()
  set_lines { "((hello))", }
  set_cursor(1, 2)
  child.type_keys("ds", ")")
  expect_lines { "(hello)", }
  expect_cursor(1, 1)
end

T["ds"]["works with text around the pair"] = function()
  set_lines { "foo (bar) baz", }
  set_cursor(1, 5)
  child.type_keys("ds", ")")
  expect_lines { "foo bar baz", }
  expect_cursor(1, 4)
end

T["ds"]["works using opening char"] = function()
  set_lines { "(hello)", }
  set_cursor(1, 1)
  child.type_keys("ds", "(")
  expect_lines { "hello", }
  expect_cursor(1, 0)
end

T["ds"]["preserves cursor line context"] = function()
  set_lines { "before (middle) after", }
  set_cursor(1, 9)
  child.type_keys("ds", ")")
  expect_lines { "before middle after", }
  expect_cursor(1, 8)
end

T["ds"]["no matching pair"] = new_set { hooks = { pre_case = stub_notify, }, }

T["ds"]["no matching pair"]["leaves buffer unchanged when no pair found"] = function()
  set_lines { "hello world", }
  set_cursor(1, 3)
  child.type_keys("ds", ")")
  expect_lines { "hello world", }
  expect_cursor(1, 3)
  expect_notify("[surround.nvim]: No matching pair", 4)
end

T["ds"]["no matching pair"]["leaves buffer unchanged with wrong pair type"] = function()
  set_lines { "(hello)", }
  set_cursor(1, 1)
  child.type_keys("ds", "]")
  expect_lines { "(hello)", }
  expect_cursor(1, 1)
  expect_notify("[surround.nvim]: No matching pair", 4)
end

T["ds"]["no matching pair"]["leaves empty buffer unchanged"] = function()
  set_lines { "", }
  set_cursor(1, 0)
  child.type_keys("ds", ")")
  expect_lines { "", }
  expect_cursor(1, 0)
  expect_notify("[surround.nvim]: No matching pair", 4)
end

T["ds"]["repeats delete surround on another pair"] = function()
  set_lines { "(hello) (world)", }
  set_cursor(1, 1)
  child.type_keys("ds", ")")
  expect_lines { "hello (world)", }
  set_cursor(1, 7)
  child.type_keys "."
  expect_lines { "hello world", }
end

T["cs"] = new_set()

T["cs"]["changes parens to brackets"] = function()
  set_lines { "(hello)", }
  set_cursor(1, 1)
  child.type_keys("cs", ")", "]")
  expect_lines { "[hello]", }
  expect_cursor(1, 1)
end

T["cs"]["changes parens to braces"] = function()
  set_lines { "(hello)", }
  set_cursor(1, 1)
  child.type_keys("cs", ")", "}")
  expect_lines { "{hello}", }
  expect_cursor(1, 1)
end

T["cs"]["changes parens to angle brackets"] = function()
  set_lines { "(hello)", }
  set_cursor(1, 1)
  child.type_keys("cs", ")", ">")
  expect_lines { "<hello>", }
  expect_cursor(1, 1)
end

T["cs"]["changes parens to quotes"] = function()
  set_lines { "(hello)", }
  set_cursor(1, 1)
  child.type_keys("cs", ")", '"')
  expect_lines { '"hello"', }
  expect_cursor(1, 1)
end

T["cs"]["changes parens to backticks"] = function()
  set_lines { "(hello)", }
  set_cursor(1, 1)
  child.type_keys("cs", ")", "`")
  expect_lines { "`hello`", }
  expect_cursor(1, 1)
end

T["cs"]["changes brackets to parens"] = function()
  set_lines { "[hello]", }
  set_cursor(1, 1)
  child.type_keys("cs", "]", ")")
  expect_lines { "(hello)", }
  expect_cursor(1, 1)
end

T["cs"]["works with text around the pair"] = function()
  set_lines { "foo (bar) baz", }
  set_cursor(1, 5)
  child.type_keys("cs", ")", "]")
  expect_lines { "foo [bar] baz", }
  expect_cursor(1, 5)
end

T["cs"]["works using opening char as source"] = function()
  set_lines { "(hello)", }
  set_cursor(1, 1)
  child.type_keys("cs", "(", "]")
  expect_lines { "[hello]", }
  expect_cursor(1, 1)
end

T["cs"]["works using opening char as target"] = function()
  set_lines { "(hello)", }
  set_cursor(1, 1)
  child.type_keys("cs", ")", "[")
  expect_lines { "[hello]", }
  expect_cursor(1, 1)
end

T["cs"]["no matching pair"] = new_set { hooks = { pre_case = stub_notify, }, }

T["cs"]["no matching pair"]["leaves buffer unchanged when no pair found"] = function()
  set_lines { "hello world", }
  set_cursor(1, 3)
  child.type_keys("cs", ")", "]")
  expect_lines { "hello world", }
  expect_cursor(1, 3)
  expect_notify("[surround.nvim]: No matching pair", 4)
end

T["cs"]["no matching pair"]["leaves buffer unchanged with wrong pair type"] = function()
  set_lines { "(hello)", }
  set_cursor(1, 1)
  child.type_keys("cs", "]", "}")
  expect_lines { "(hello)", }
  expect_cursor(1, 1)
  expect_notify("[surround.nvim]: No matching pair", 4)
end

T["cs"]["no matching pair"]["leaves empty buffer unchanged"] = function()
  set_lines { "", }
  set_cursor(1, 0)
  child.type_keys("cs", ")", "]")
  expect_lines { "", }
  expect_cursor(1, 0)
  expect_notify("[surround.nvim]: No matching pair", 4)
end

T["cs"]["invalid pair"] = new_set { hooks = { pre_case = stub_notify, }, }

T["cs"]["invalid pair"]["leaves buffer unchanged for invalid target pair"] = function()
  set_lines { "(hello)", }
  set_cursor(1, 1)
  child.type_keys("cs", ")", "z")
  expect_lines { "(hello)", }
  expect_cursor(1, 1)
  expect_notify("[surround.nvim]: Invalid pair", 4)
end

T["cs"]["repeats change surround on another pair"] = function()
  set_lines { "(hello) (world)", }
  set_cursor(1, 1)
  child.type_keys("cs", ")", "]")
  expect_lines { "[hello] (world)", }
  set_cursor(1, 9)
  child.type_keys "."
  expect_lines { "[hello] [world]", }
end

T["ys"] = new_set()

T["ys"]["surrounds word with parens"] = function()
  set_lines { "hello", }
  set_cursor(1, 0)
  child.type_keys("ys", "iw", ")")
  expect_lines { "(hello)", }
  expect_cursor(1, 1)
end

T["ys"]["surrounds word with brackets"] = function()
  set_lines { "hello", }
  set_cursor(1, 0)
  child.type_keys("ys", "iw", "]")
  expect_lines { "[hello]", }
  expect_cursor(1, 1)
end

T["ys"]["surrounds word with braces"] = function()
  set_lines { "hello", }
  set_cursor(1, 0)
  child.type_keys("ys", "iw", "}")
  expect_lines { "{hello}", }
  expect_cursor(1, 1)
end

T["ys"]["surrounds word with quotes"] = function()
  set_lines { "hello", }
  set_cursor(1, 0)
  child.type_keys("ys", "iw", '"')
  expect_lines { '"hello"', }
  expect_cursor(1, 1)
end

T["ys"]["surrounds word with single quotes"] = function()
  set_lines { "hello", }
  set_cursor(1, 0)
  child.type_keys("ys", "iw", "'")
  expect_lines { "'hello'", }
  expect_cursor(1, 1)
end

T["ys"]["surrounds word with angle brackets"] = function()
  set_lines { "hello", }
  set_cursor(1, 0)
  child.type_keys("ys", "iw", ">")
  expect_lines { "<hello>", }
  expect_cursor(1, 1)
end

T["ys"]["surrounds inner word in context"] = function()
  set_lines { "foo bar baz", }
  set_cursor(1, 4)
  child.type_keys("ys", "iw", ")")
  expect_lines { "foo (bar) baz", }
  expect_cursor(1, 5)
end

T["ys"]["surrounds with motion e"] = function()
  set_lines { "hello world", }
  set_cursor(1, 0)
  child.type_keys("ys", "e", ")")
  expect_lines { "(hello) world", }
  expect_cursor(1, 1)
end

T["ys"]["surrounds to end of line with $"] = function()
  set_lines { "hello world", }
  set_cursor(1, 0)
  child.type_keys("ys", "$", ")")
  expect_lines { "(hello world)", }
  expect_cursor(1, 1)
end

T["ys"]["works with opening char"] = function()
  set_lines { "hello", }
  set_cursor(1, 0)
  child.type_keys("ys", "iw", "(")
  expect_lines { "(hello)", }
  expect_cursor(1, 1)
end

T["ys"]["surrounds word with backticks"] = function()
  set_lines { "hello", }
  set_cursor(1, 0)
  child.type_keys("ys", "iw", "`")
  expect_lines { "`hello`", }
  expect_cursor(1, 1)
end

T["ys"]["invalid pair"] = new_set { hooks = { pre_case = stub_notify, }, }

T["ys"]["invalid pair"]["leaves buffer unchanged for invalid pair"] = function()
  set_lines { "hello", }
  set_cursor(1, 0)
  child.type_keys("ys", "iw", "z")
  expect_lines { "hello", }
  expect_cursor(1, 0)
  expect_notify("[surround.nvim]: Invalid pair", 4)
end

T["ys"]["repeats add surround on another word"] = function()
  set_lines { "hello world", }
  set_cursor(1, 0)
  child.type_keys("ys", "iw", ")")
  expect_lines { "(hello) world", }
  set_cursor(1, 8)
  child.type_keys "."
  expect_lines { "(hello) (world)", }
end

return T
