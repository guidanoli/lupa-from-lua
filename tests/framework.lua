---------------------------------
-- Unit testing framework
---------------------------------

local Framework = {
	colors = {
		black = 30,
		red = 31,
		green = 32,
		yellow = 33,
		blue = 34,
		magenta = 35,
		cyan = 36,
		white = 37,
	}
}

function Framework:Print(tag, tagcolor, message)
	local tagcolorcode = self.colors[tagcolor] or 0
	print("[\27[" .. tagcolorcode .. "m " .. tag .. "\27[0m ] " .. message)
end

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
function Framework:RunTestbench(tb)
	self:Print("####", nil, "Testing " .. tb.name)

	local passed = 0
	local failed = 0

	for testname, testfunc in pairs(tb) do
		if testname:find("^Test") ~= nil then
			local ok, errmsg = pcall(testfunc, tb)
			if ok then
				self:Print("PASS", "green", testname)
				passed = passed + 1
			else
				self:Print("FAIL", "red", testname)
				print(errmsg)
				failed = failed + 1
			end
		end
	end

	self:Print("####", nil, (failed + passed) .. " tests run")
	if failed > 0 then
		self:Print("####", nil, failed .. " failed")
	else
		self:Print("####", nil, "All passed")
	end

	return {
		total = failed + passed,
		failed = failed,
		passed = passed
	}
end

return Framework
