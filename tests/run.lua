---------------------------------
-- Testbench running script
---------------------------------

local utils = require 'tests.utils'

-- Run all test cases of a test bench, printing a report at the end
-- Arguments:
--   testbenchname = (test bench name) [string]
-- Returns:
--   [1] = (found test?) [bool]
--   [2] = if [1] == false, error message [string]
--         if [1] == true, test report [table]
--         {
--           passed = (passed test cases count) [number],
--           failed = (failed test cases count) [number],
--         }
return function(testbenchname)
	local passed = 0
	local failed = 0
	local ok, testbench = pcall(require, testbenchname)

	if not ok then
		return false, testbench
	end

	utils:Print("####", nil, "Running " .. testbenchname)
	for testname, testfunc in utils:SortedPairs(testbench) do
		if type(testfunc) == "function" then
			local ok, errmsg = pcall(testfunc, testbench)
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
	else
		utils:Print("####", nil, "All passed")
	end

	return true, {
		failed = failed,
		passed = passed
	}
end
