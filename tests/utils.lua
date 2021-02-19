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

-- Converts Lua object into a pretty string
-- Aimed for visualizing complex tables
-- Arguments:
-- * obj [object]
-- Return:
-- * str [string]
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
			local chars = {
				['\a'] = '\\a',
				['\b'] = '\\b',
				['\f'] = '\\f',
				['\n'] = '\\n',
				['\r'] = '\\r',
				['\t'] = '\\t',
				['\v'] = '\\v',
			}
			for char, flatchar in pairs(chars) do
				obj = obj:gsub(char, flatchar)
			end
			return '"' .. obj .. '"'
		else
			return tostring(obj)
		end
	end

	return _pretty(obj, "", {})
end

-- Similar to regular 'pairs' function
-- but sorted by table keys
-- Arguments:
-- t = (table to be iterated) [table]
-- Return:
-- * iterator that returns key and value
function Utils:SortedPairs(t)
	local a = {}
	for n in pairs(t) do table.insert(a, n) end
	table.sort(a, function(a, b)
		local ta, tb = type(a), type(b)
		return ta < tb or ta == tb and a < b
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

-- Print message with colored tag
-- Arguments:
-- tag = (message tag) [string]
-- tagcolor = (message tag color) [string, nil]
--            default: no color
-- message = (actual message) [string]
function Utils:Print(tag, tagcolor, message)
	local tagcolorcode = self.colors[tagcolor] or 0
	print("[\27[" .. tagcolorcode .. "m " .. tag .. "\27[0m ] " .. message)
end

-- Asserts arguments have equal type
function Utils:TestTypeEq(a, b)
	ta, tb = type(a), type(b)
	assert(ta == tb,
		tostring(a) .. " and " .. tostring(b) ..
		" have different type (" .. ta ..
		" and " .. tb .. " respectively)")
end

-- Asserts arguments have equal math.type (if supported)
function Utils:TestMathTypeEq(a, b)
	if math.type then
		ta, tb = math.type(a), math.type(b)
		assert(ta == tb,
			tostring(a) .. " and " .. tostring(b) ..
			" have different mathematical types (" ..
			ta .. " and " .. tb .. " respectively)")
	end
end

-- Asserts arguments have equal type and, if supported, math.type
-- and equal numerical value
function Utils:TestNumEq(a, b)
	self:TestTypeEq(a, b)
	self:TestMathTypeEq(a, b)
	assert(a == b, tostring(a) .. " != " .. tostring(b))
end

return Utils
