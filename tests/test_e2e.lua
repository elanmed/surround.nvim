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

local get_lines = function() return child.api.nvim_buf_get_lines(0, 0, -1, true) end
local set_lines = function(lines) child.api.nvim_buf_set_lines(0, 0, -1, true, lines) end
local set_cursor = function(row, col) child.api.nvim_win_set_cursor(0, { row, col, }) end

T["ds"] = new_set()

T["ds"]["deletes surrounding parentheses"] = function()
  set_lines { "(hello)", }
  set_cursor(1, 1)
  child.type_keys("ds", ")")
  eq(get_lines(), { "hello", })
end

T["ds"]["deletes surrounding brackets"] = function()
  set_lines { "[hello]", }
  set_cursor(1, 1)
  child.type_keys("ds", "]")
  eq(get_lines(), { "hello", })
end

T["ds"]["deletes surrounding braces"] = function()
  set_lines { "{hello}", }
  set_cursor(1, 1)
  child.type_keys("ds", "}")
  eq(get_lines(), { "hello", })
end

T["ds"]["deletes surrounding angle brackets"] = function()
  set_lines { "<hello>", }
  set_cursor(1, 1)
  child.type_keys("ds", ">")
  eq(get_lines(), { "hello", })
end

T["ds"]["deletes surrounding quotes"] = function()
  set_lines { '"hello"', }
  set_cursor(1, 1)
  child.type_keys("ds", '"')
  eq(get_lines(), { "hello", })
end

T["ds"]["deletes surrounding single quotes"] = function()
  set_lines { "'hello'", }
  set_cursor(1, 2)
  child.type_keys("ds", "'")
  eq(get_lines(), { "hello", })
end

T["ds"]["works with nested pairs"] = function()
  set_lines { "((hello))", }
  set_cursor(1, 2)
  child.type_keys("ds", ")")
  eq(get_lines(), { "(hello)", })
end

T["ds"]["works with text around the pair"] = function()
  set_lines { "foo (bar) baz", }
  set_cursor(1, 5)
  child.type_keys("ds", ")")
  eq(get_lines(), { "foo bar baz", })
end

T["ds"]["works using opening char"] = function()
  set_lines { "(hello)", }
  set_cursor(1, 1)
  child.type_keys("ds", "(")
  eq(get_lines(), { "hello", })
end

T["ds"]["preserves cursor line context"] = function()
  set_lines { "before (middle) after", }
  set_cursor(1, 9)
  child.type_keys("ds", ")")
  eq(get_lines(), { "before middle after", })
end

T["cs"] = new_set()

T["cs"]["changes parens to brackets"] = function()
  set_lines { "(hello)", }
  set_cursor(1, 1)
  child.type_keys("cs", ")", "]")
  eq(get_lines(), { "[hello]", })
end

T["cs"]["changes brackets to braces"] = function()
  set_lines { "[hello]", }
  set_cursor(1, 1)
  child.type_keys("cs", "]", "}")
  eq(get_lines(), { "{hello}", })
end

T["cs"]["changes braces to parens"] = function()
  set_lines { "{hello}", }
  set_cursor(1, 1)
  child.type_keys("cs", "}", ")")
  eq(get_lines(), { "(hello)", })
end

T["cs"]["changes parens to angle brackets"] = function()
  set_lines { "(hello)", }
  set_cursor(1, 1)
  child.type_keys("cs", ")", ">")
  eq(get_lines(), { "<hello>", })
end

T["cs"]["changes quotes to parens"] = function()
  set_lines { '"hello"', }
  set_cursor(1, 1)
  child.type_keys("cs", '"', ")")
  eq(get_lines(), { "(hello)", })
end

T["cs"]["changes parens to quotes"] = function()
  set_lines { "(hello)", }
  set_cursor(1, 1)
  child.type_keys("cs", ")", '"')
  eq(get_lines(), { '"hello"', })
end

T["cs"]["changes to same-char delimiters"] = function()
  set_lines { "(hello)", }
  set_cursor(1, 1)
  child.type_keys("cs", ")", "'")
  eq(get_lines(), { "'hello'", })
end

T["cs"]["works with text around the pair"] = function()
  set_lines { "foo (bar) baz", }
  set_cursor(1, 5)
  child.type_keys("cs", ")", "]")
  eq(get_lines(), { "foo [bar] baz", })
end

T["cs"]["works using opening char as source"] = function()
  set_lines { "(hello)", }
  set_cursor(1, 1)
  child.type_keys("cs", "(", "]")
  eq(get_lines(), { "[hello]", })
end

T["cs"]["works using opening char as target"] = function()
  set_lines { "(hello)", }
  set_cursor(1, 1)
  child.type_keys("cs", ")", "[")
  eq(get_lines(), { "[hello]", })
end

T["ys"] = new_set()

T["ys"]["surrounds word with parens"] = function()
  set_lines { "hello", }
  set_cursor(1, 0)
  child.type_keys("ys", "iw", ")")
  eq(get_lines(), { "(hello)", })
end

T["ys"]["surrounds word with brackets"] = function()
  set_lines { "hello", }
  set_cursor(1, 0)
  child.type_keys("ys", "iw", "]")
  eq(get_lines(), { "[hello]", })
end

T["ys"]["surrounds word with braces"] = function()
  set_lines { "hello", }
  set_cursor(1, 0)
  child.type_keys("ys", "iw", "}")
  eq(get_lines(), { "{hello}", })
end

T["ys"]["surrounds word with quotes"] = function()
  set_lines { "hello", }
  set_cursor(1, 0)
  child.type_keys("ys", "iw", '"')
  eq(get_lines(), { '"hello"', })
end

T["ys"]["surrounds word with single quotes"] = function()
  set_lines { "hello", }
  set_cursor(1, 0)
  child.type_keys("ys", "iw", "'")
  eq(get_lines(), { "'hello'", })
end

T["ys"]["surrounds word with angle brackets"] = function()
  set_lines { "hello", }
  set_cursor(1, 0)
  child.type_keys("ys", "iw", ">")
  eq(get_lines(), { "<hello>", })
end

T["ys"]["surrounds inner word in context"] = function()
  set_lines { "foo bar baz", }
  set_cursor(1, 4)
  child.type_keys("ys", "iw", ")")
  eq(get_lines(), { "foo (bar) baz", })
end

T["ys"]["surrounds with motion e"] = function()
  set_lines { "hello world", }
  set_cursor(1, 0)
  child.type_keys("ys", "e", ")")
  eq(get_lines(), { "(hello) world", })
end

T["ys"]["surrounds to end of line with $"] = function()
  set_lines { "hello world", }
  set_cursor(1, 0)
  child.type_keys("ys", "$", ")")
  eq(get_lines(), { "(hello world)", })
end

T["ys"]["works with opening char"] = function()
  set_lines { "hello", }
  set_cursor(1, 0)
  child.type_keys("ys", "iw", "(")
  eq(get_lines(), { "(hello)", })
end

return T
