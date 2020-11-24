-- Tests lupafromlua
-- Run from root directory
-- $ lua tests/test.lua

package.cpath = package.cpath .. ";./lib/?.so"

local python = assert(require("lupafromlua"))

Testbench = {}

function Testbench:TestSomethingTrue()
	assert(true)
end

function Testbench:TestSomethingFalse()
	assert(false)
end

print("Running tests...")
for testcase, testfunc in pairs(Testbench) do
	local ok, errmsg = pcall(testfunc, Testbench)
	if ok then
		print(testcase, "ok")
	else
		print(testcase, errmsg)
	end
end
