---------------------------------
-- Utility functions
---------------------------------

local Utils = {
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

-- Utils:Pretty(obj) : string
-- Arguments:
--   obj
-- Returns:
--   Representation of obj
-- Example:
--   Utils:Pretty({a = 10, b = {}}) ->
--   {
--       ["a"] = 10,
--       ["b"] = {},
--   }
function Utils:Pretty(obj)
	local function _pretty(obj, pad, visited)
		if type(obj) == "table" then
			if next(obj) == nil then
				return "{}"
			elseif visited[obj] then
				return "{...}"
			else
				local s = "{\n"
				local newpad = pad .. "    "
				visited[obj] = true
				for key, value in self:SortedPairs(obj) do
					s = s .. newpad .. "[" .. _pretty(key, newpad, visited) .. "] = " .. 
					                          _pretty(value, newpad, visited) .. ",\n"
				end
				return s .. pad .. "}"
			end
		elseif type(obj) == "string" then
			return string.format("%q", obj)
		else
			return tostring(obj)
		end
	end

	return _pretty(obj, "", {})
end

-- Utils:SortedPairs(t) : function
-- Arguments:
--   t : table
-- Return:
--   Iterator similar to pairs, but with sorted keys
-- Example:
--   Utils:SortedPairs({z = 2, a = 3, f = 5}) ->
--     ('a', 3)
--     ('f', 5)
--     ('z', 2)
function Utils:SortedPairs(t)
	local a = {}
	for n in pairs(t) do table.insert(a, n) end
	table.sort(a, function(a, b)
		local ta, tb = type(a), type(b)
		if ta == tb then
			if ta == 'string' or ta == 'number' then
				return a < b
			elseif ta == 'boolean' then
				return b and not a
			else
				return false -- Can't compare
			end
		else
			return ta < tb -- Arbitrary type order
		end
	end)
	local i = 0 -- iterator variable
	local iter = function() -- iterator function
		i = i + 1
		if a[i] == nil then return nil
		else return a[i], t[a[i]]
		end
	end
	return iter
end

-- Utils:Average(t) : number
-- Arguments:
--   t : table
--   n - size of t : number or nil
-- Returns:
--   Average of numbers in array
-- Example:
--   Utils:Average({1, 2, 3}) -> 2
function Utils:Average(t, n)
	local avg = 0
	n = n or #t
	for i = 1, n do
		avg = avg + t[i] / n
	end
	return avg
end

-- Utils:Stddev(t) : number
-- Arguments:
--   t : table
--   n - size of t : number or nil
--   avg - average of numbers : number or nil
-- Returns:
--   Standard deviation of numbers in array
-- Example:
--   Utils:Stddev({1, 2, 3}) -> 0.81649658092773
function Utils:Stddev(t, n, avg)
	local var = 0
	n = n or #t
	avg = avg or self:Average(t, n)
	for i = 1, n do
		local dev = t[i] - avg
		var = var + dev * dev / n
	end
	return math.sqrt(var)
end

-- Utils:Time(f) : number
-- Arguments:
--   f : function
-- Returns:
--   Number of seconds it takes to call f
-- Example:
--   Utils:Time(function() end) -> 7e-6
function Utils:Time(f)
	local ti = os.clock()
	f()
	local tf = os.clock()
	return tf - ti
end

-- Utils:ProgressBar(w, p) : string
-- Arguments:
--   w - bar width : number of integral type
--   p - percentage of completeness : number between 0 and 1
-- Returns:
--   Representation of a progress bar of w
--   characters and p of completeness
function Utils:ProgressBar(w, p)
	if w < 8 then
		local filled = math.floor(w*p)
		local unfilled = w - filled
		return string.rep('#', filled) .. string.rep('-', unfilled)
	else
		local number = string.format("%3d%%", math.floor(p * 100))
		w = w - string.len(number) - 3
		local filled = math.floor(w*p)
		local unfilled = w - filled
		return "[" .. string.rep('#', filled) .. string.rep(' ', unfilled) .. "] " .. number
	end
end

-- Utils:GetProgressBarCallback(w, fp) : function
-- Arguments:
--   w - bar width : number of integral type
--   fp - file pointer : file
-- Returns:
--   Callback that receives percentage of completeness
--   and writes a progress bar of width w to fp
-- Example:
--   local cb = Utils:GetProgressBarCallback(80, io.stderr)
--   local avg, stddev = Utils:Benchmark(f, n, cb)
function Utils:GetProgressBarCallback(w, fp)
	local last_pb = ''
	return function(p)
		local pb = self:ProgressBar(w, p)
		if pb ~= last_pb then
			fp:write((p == 0 and '' or '\r') .. pb .. (p == 1 and '\n' or ''))
			fp:flush()
			last_pb = pb
		end
	end
end

-- Utils:Benchmark(f, n) : number, number
-- Arguments:
--   f : function
--   n - number of loops : number
--   cb - progress callback : function or nil
-- Returns:
--   Average and standard deviation of number
--   of seconds it takes to run f
-- Example:
--   Utils:TimeStats(function() end, 1000000) ->
--   5.6543300000012e-07	5.0961605401745e-07
function Utils:Benchmark(f, n, cb)
	local t = {}
	if cb then cb(0) end
	for i = 1, n do
		t[i] = self:Time(f)
		if cb then cb(i/n) end
	end
	local avg = self:Average(t, n)
	local stddev = self:Stddev(t, n, avg)
	return avg, stddev
end

-- Utils:Print(tag, tagcolor, message)
-- Arguments:
--   tag - message tag : string
--   tagcolor - message tag color : string or nil
--              default: no color
--   message : str
-- Example:
--   Utils:Print('LOG', 'yellow', 'Starting...')
function Utils:Print(tag, tagcolor, message)
	local tagcolorcode = self.colors[tagcolor] or 0
	print("[\27[" .. tagcolorcode .. "m " .. tag .. "\27[0m ] " .. message)
end

-- Utils:TestTypeEq(a, b)
-- Asserts a and b are of the same type
function Utils:TestTypeEq(a, b)
	ta, tb = type(a), type(b)
	assert(ta == tb,
		tostring(a) .. " and " .. tostring(b) ..
		" have different type (" .. ta ..
		" and " .. tb .. " respectively)")
end

-- Utils:TestMathTypeEq(a, b)
-- Asserts a and b are of the same mathematical type
-- Observation:
--   If math.type is not defined, this function always succeeds
function Utils:TestMathTypeEq(a, b)
	if math.type then
		ta, tb = math.type(a), math.type(b)
		assert(ta == tb,
			tostring(a) .. " and " .. tostring(b) ..
			" have different mathematical types (" ..
			ta .. " and " .. tb .. " respectively)")
	end
end

-- Utils:TestNumEq(a, b)
-- Asserts a and b are of the same type, mathematical type
-- (if supported) and numerical value
function Utils:TestNumEq(a, b)
	self:TestTypeEq(a, b)
	self:TestMathTypeEq(a, b)
	assert(a == b, tostring(a) .. " != " .. tostring(b))
end

return Utils
