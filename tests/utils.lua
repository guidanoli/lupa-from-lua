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

return utils
