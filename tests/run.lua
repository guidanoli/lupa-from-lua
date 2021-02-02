---------------------------------
-- Testbench running script
---------------------------------

local utils = require 'tests.utils'

-- Run all test cases of a test bench, printing a report at the end
-- Arguments:
-- tb = {
--   name = (testbench name) [string],
--   Test.* = (test case function) [function],
-- }
-- Returns:
-- * {
--   total = (total test cases count) [number],
--   passed = (passed test cases count) [number],
--   failed = (failed test cases count) [number],
-- }
local run_testbench = function(tb)
	utils:Print("####", nil, "Testing " .. tb.name)

	local passed = 0
	local failed = 0

	for testname, testfunc in utils:SortedPairs(tb) do
		if testname:find("^Test") ~= nil then
			local ok, errmsg = pcall(testfunc, tb)
			if ok then
				utils:Print("PASS", "green", testname)
				passed = passed + 1
			else
				utils:Print("FAIL", "red", testname)
				print(errmsg)
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

	return {
		total = failed + passed,
		failed = failed,
		passed = passed
	}
end

if #arg == 0 then
	local s = ""
	local i = 0
	while arg[i] ~= nil do
		s = arg[i] .. " " .. s
		i = i - 1
	end
	if string.len(s) == 0 then
		s = "lua tests/run.lua "
	end
	io.stderr:write("Usage: " .. s .. "<testbenchname>\n")
	os.exit(1)
else
	local testbenchname = "tests." .. arg[1]
	local ok, ret = pcall(require, testbenchname)
	if not ok then
		io.stderr:write(ret)
		os.exit(1)
	else
		local results = run_testbench(ret)
		if results.failed > 0 then
			os.exit(1)
		end
	end
end
