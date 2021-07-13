---------------------------------
-- Test running script
---------------------------------

-- Lua 5.1 compatibility
require "tests.compat"

local utils = require 'tests.utils'

local t = {}

-- Run all test cases, printing a report at the end
-- If at least one test fails, returns false and an error message
-- If no tests fail, returns true
function t.safe_run()
	local passed = 0
	local failed = 0
	local tb = require "tests.main"
	utils:Print("####", nil, "Running all tests")
	for testname, testfunc in pairs(tb) do
		if type(testfunc) == "function" and
				type(testname) == "string" and
				not testname:find("^_") then
			local ok, errmsg = xpcall(
					function() return testfunc(tb) end,
					function(o) return debug.traceback(tostring(o)) end)
			if ok then
				utils:Print("PASS", "green", testname)
				passed = passed + 1
			else
				utils:Print("FAIL", "red", testname .. '\n' .. errmsg)
				failed = failed + 1
			end
		end
	end
	utils:Print("####", nil, (failed + passed) .. " test(s) run")
	if failed > 0 then
		utils:Print("####", nil, failed .. " failed")
		return false, failed .. " test(s) failed"
	else
		utils:Print("####", nil, "All passed")
		return true
	end
end

-- Similar to t.safe_run, but asserts that all tests pass
function t.run()
	assert(t.safe_run())
end

if type(arg) == "table" and arg[0]:find("test%.lua$") then
	for i, argi in ipairs(arg) do
		if argi == '--seed' then
			local seed = assert(arg[i+1], 'expected seed')
			local seednum = assert(tonumber(seed), 'seed not a number')
			math.randomseed(seednum)
		end
	end
	t.run()
end

return t
