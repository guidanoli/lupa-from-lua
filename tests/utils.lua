---------------------------------
-- Utility functions
---------------------------------

local utils = {}

-- utils.colors : table
-- Contains labeled ASCII color codes
utils.colors = {
	black = 30,
	red = 31,
	green = 32,
	yellow = 33,
	blue = 34,
	magenta = 35,
	cyan = 36,
	white = 37,
}

-- utils:Pretty(obj) : string
-- Arguments:
--   obj
-- Returns:
--   Representation of obj
-- Example:
--   utils:Pretty({a = 10, b = {}}) ->
--   {
--       ["a"] = 10,
--       ["b"] = {},
--   }
function utils:Pretty(obj)
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

-- utils:SortedPairs(t) : function
-- Arguments:
--   t : table
-- Return:
--   Iterator similar to pairs, but with sorted keys
-- Example:
--   local t = {z = 2, a = 3, f = 5}
--   for k, v in utils:SortedPairs(t) do
--   	print(k, v)
--   end
--   --> a	3
--       f	5
--       z	2
function utils:SortedPairs(t)
	local keys = {}
	for key in pairs(t) do table.insert(keys, key) end
	table.sort(keys, function(a, b)
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
		local key = keys[i]
		if key == nil then return nil
		else return key, t[key]
		end
	end
	return iter
end

-- utils:Time(f) : number
-- Arguments:
--   f : function
-- Returns:
--   Number of seconds it takes to call f
-- Example:
--   utils:Time(function() end) -> 7e-6
function utils:Time(f)
	local ti = os.clock()
	f()
	local tf = os.clock()
	return tf - ti
end

-- utils:ProgressBar(w, p) : string
-- Arguments:
--   w - bar width : number of integral type
--   p - percentage of completeness : number between 0 and 1
-- Returns:
--   Representation of a progress bar of w characters and p of completeness
function utils:ProgressBar(w, p)
	return string.format("[%-" .. (w - 7) .. "s] %3d%%", string.rep('=', math.floor((w - 7) * p)), math.floor(p * 100))
end

-- utils:GetProgressBarCallback(w, fp) : function
-- Arguments:
--   w - bar width : number of integral type
--   fp - file pointer : file
-- Returns:
--   Callback that receives percentage of completeness
--   and writes a progress bar of width w to fp
-- Example:
--   local cb = utils:GetProgressBarCallback(80, io.stderr)
--   local avg, stddev = utils:Benchmark(f, n, cb)
function utils:GetProgressBarCallback(w, fp)
	local last
	return function(p)
		local curr = math.floor(p * 100)
		if curr ~= last then
			local pb = self:ProgressBar(w, p)
			fp:write('\r' .. pb .. (p == 1 and '\n' or ''))
			fp:flush()
			last = curr
		end
	end
end

-- utils:Benchmark(f, n, progress_cb) : number, number
-- Arguments:
--   f : function
--   n - number of loops : number
--   progress_cb : function or nil
-- Returns:
--   Mean and standard deviation of number
--   of seconds it takes to run f
-- Example:
--   utils:Benchmark(function() end, 1000000) ->
--   5.6543300000012e-07	5.0961605401745e-07
function utils:Benchmark(f, n, progress_cb)
	local mean = 0
	local var = 0
	for i = 1, n do
		local t = self:Time(f)
		local newmean = (t + (i - 1) * mean) / i
		var = var + (t - mean) * (t - newmean)
		mean = newmean
		if progress_cb then progress_cb(i / n) end
	end
	return mean, math.sqrt(var / n)
end

-- utils:Print(tag, tagcolor, message)
-- Arguments:
--   tag - message tag : string
--   tagcolor - message tag color : string or nil
--              default: no color
--   message : str
-- Example:
--   utils:Print('LOG', 'yellow', 'Starting...')
function utils:Print(tag, tagcolor, message)
	local tagcolorcode = self.colors[tagcolor] or 0
	print("[\27[" .. tagcolorcode .. "m " .. tag .. "\27[0m ] " .. message)
end

-- utils:TestTypeEq(a, b)
-- Asserts a and b are of the same type
function utils:TestTypeEq(a, b)
	ta, tb = type(a), type(b)
	assert(ta == tb,
		tostring(a) .. " and " .. tostring(b) ..
		" have different type (" .. ta ..
		" and " .. tb .. " respectively)")
end

-- utils:TestMathTypeEq(a, b)
-- Asserts a and b are of the same mathematical type
-- Observation:
--   If math.type is not defined, this function always succeeds
function utils:TestMathTypeEq(a, b)
	if math.type then
		ta, tb = math.type(a), math.type(b)
		assert(ta == tb,
			tostring(a) .. " and " .. tostring(b) ..
			" have different mathematical types (" ..
			ta .. " and " .. tb .. " respectively)")
	end
end

-- utils:TestNumEq(a, b)
-- Asserts a and b are of the same type, mathematical type
-- (if supported) and numerical value
function utils:TestNumEq(a, b)
	self:TestTypeEq(a, b)
	self:TestMathTypeEq(a, b)
	assert(a == b, tostring(a) .. " != " .. tostring(b))
end

return utils
