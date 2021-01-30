-----------------------------------------
-- Lupa from lua & utility functions
-----------------------------------------

local python = require "lupafromlua"

if not table.pack then
	table.pack = function(...)
		return {n=select('#',...); ...}
	end
end

if not table.unpack then
	table.unpack = unpack
end

python.equal = python.eval("lambda x, y: x == y")

python.wrap = python.eval("lambda f: lambda *args: f(*args)")

python.list = function(...)
	local l = python.builtins.list()
	local append_func = python.as_attrgetter(l).append
	local t = table.pack(...)
	local i = 1
	while i <= t.n do
		local item = t[i]
		append_func(item)
		i = i + 1
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

python.import = function(...)
	local t = table.pack(...)
	local i = 1
	while i <= t.n do
		local module = t[i]
		python.exec("import " .. module)
		i = i + 1
	end
end

return python
