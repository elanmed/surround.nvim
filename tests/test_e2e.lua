require "mini.test".setup()

local T = MiniTest.new_set()
T["surround"] = MiniTest.new_set()
T["surround"]["dummy"] = function()
  MiniTest.expect.equality(true, true)
end

return T
