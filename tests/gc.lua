-----------------------------------------------------------
-- Tests the Lupa garbage collection algorithm
-- Run from the project root directory
-----------------------------------------------------------

local python = require 'lupafromlua'

-----------------------------------------------------------
-- Test cases
-----------------------------------------------------------

local Testbench = {
	name = "lupafromluagc",
}


function Testbench:CopyInLua()
	collectgarbage()
	print("Collected garbage")

	local l = python.builtins.list()
	print("Created Python list l and reference to it in Lua")

	collectgarbage()
	print("Collected garbage")

	local lcopy = l
	print("Created another reference to Python list l")

	collectgarbage()
	print("Collected garbage")

	l = nil
	print("Removed original reference to Python list l from Lua")

	collectgarbage()
	print("Collected garbage")

	lcopy = nil
	print("Removed second reference to Python list l from Lua")

	collectgarbage()
	print("Collected garbage")
end

return Testbench
