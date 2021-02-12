---------------------------------
-- Test running script
---------------------------------

local utils = require 'tests.utils'

local t = {}

-- Run all test cases, printing a report at the end
-- If one test fails, exits with error code 1
function t.run()
	local passed = 0
	local failed = 0
	local tb = require("tests.main")
	utils:Print("####", nil, "Running all tests")
	for testname, testfunc in utils:SortedPairs(tb) do
		if type(testfunc) == "function" then
			local ok, errmsg = pcall(testfunc, tb)
			if ok then
				utils:Print("PASS", "green", testname)
				passed = passed + 1
			else
				utils:Print("FAIL", "red", testname)
				io.stderr:write(tostring(errmsg) .. "\n")
				failed = failed + 1
			end
		end
	end
	utils:Print("####", nil, (failed + passed) .. " tests run")
	if failed > 0 then
		utils:Print("####", nil, failed .. " failed")
		os.exit(1)
	else
		utils:Print("####", nil, "All passed")
	end
end

if type(arg) == "table" and arg[0] == "test.lua" then
	t.run()
end

return t
