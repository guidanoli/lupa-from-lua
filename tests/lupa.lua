-----------------------------------------
-- Lupa from lua & utility functions
-----------------------------------------

local python = require "lupafromlua"

python.equal = python.eval("lambda x, y: x == y")

python.list = function(...)
	local l = python.builtins.list()
	for _, item in ipairs(table.pack(...)) do
		python.as_attrgetter(l).append(item)
	end
	return l
end

python.tuple = function(...)
	local l = python.list(...)
	return python.builtins.tuple(l)
end

python.set = function(...)
	local l = python.list(...)
	return python.builtins.set(l)
end

python.dict = function(...)
	local d = python.builtins.dict()
	local t = table.pack(...)
	local i = 1
	while i <= t.n do
		local key, value = t[i], t[i+1]
		d[key] = value
		i = i + 2
	end
	return d
end

return python