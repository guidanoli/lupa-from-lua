-- Lua 5.1 compatiblity

local compat = {}

if not table.pack then
	table.pack = function(...)
		return {n=select('#',...); ...}
	end
end

if not table.unpack then
	table.unpack = unpack
end

if loadstring then
	load = function(o, ...)
		if type(o) == 'string' then
			return loadstring(o, ...)
		else
			return load(o, ...)
		end
	end
end

return compat
