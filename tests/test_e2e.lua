require "mini.test".setup()

local T = MiniTest.new_set()
T["wrap"] = MiniTest.new_set()
T["wrap"]["dummy"] = function()
  MiniTest.expect.equality(true, true)
end

return T
