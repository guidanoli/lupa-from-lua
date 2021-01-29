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

-- Similar to regular 'pairs' function
-- but sorted by table keys
-- Arguments:
-- t = (table to be iterated) [table]
-- f = (sorting function) [function, nil]
--     default: '<' operator
-- Return:
-- * iterator that returns key and value
function Framework:SortedPairs(t, f)
	local a = {}
	for n in pairs(t) do table.insert(a, n) end
	table.sort(a, f)
	local i = 0 -- iterator variable
	local iter = function() -- iterator function
		i = i + 1
		if a[i] == nil then return nil
		else return a[i], t[a[i]]
		end
	end
	return iter
end

-- Print message with colored tag
-- Arguments:
-- tag = (message tag) [string]
-- tagcolor = (message tag color) [string, nil]
--            default: no color
-- message = (actual message) [string]
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

	for testname, testfunc in self:SortedPairs(tb) do
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

function Framework:TestTypeEq(a, b)
	ta, tb = type(a), type(b)
	assert(ta == tb,
		tostring(a) .. " and " .. tostring(b) ..
		" have different type (" .. ta ..
		" and " .. tb .. " respectively)")
end

function Framework:TestMathTypeEq(a, b)
	if math.type then
		ta, tb = math.type(a), math.type(b)
		assert(ta == tb,
			tostring(a) .. " and " .. tostring(b) ..
			" have different mathematical types (" ..
			ta .. " and " .. tb .. " respectively)")
	end
end

function Framework:TestNumEq(a, b)
	self:TestTypeEq(a, b)
	self:TestMathTypeEq(a, b)
	assert(a == b,
		tostring(a) .. " != " .. tostring(b))
end

return Framework
