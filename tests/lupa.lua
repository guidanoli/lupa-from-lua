-----------------------------------------
-- Lupa from lua & utility functions
-----------------------------------------

local python = require "lupafromlua"

-----------------------------------------
-- Compatibility code
-----------------------------------------

if not table.pack then
	table.pack = function(...)
		return {n=select('#',...); ...}
	end
end

if not table.unpack then
	table.unpack = unpack
end

-----------------------------------------
-- Helper functions
-----------------------------------------

local function bindcontainer(name, addfuncname)
	local containerclass = python.builtins[name]
	local add = python.as_attrgetter(containerclass)[addfuncname]
	return function(...)
		local container = containerclass()
		local t = table.pack(...)
		local i = 1
		while i <= t.n do
			local item = t[i]
			add(container, item)
			i = i + 1
		end
		return container
	end
end

-----------------------------------------
-- Utility functions
-----------------------------------------

-- python.equal(a, b) : userdata
-- Arguments:
--   a, b - operands
-- Returns:
--   Result of a == b in Python
-- Example:
--   python.equal(python.list(), python.list()) -> true
python.equal = python.eval("lambda x, y: x == y")

-- python.wrap(f) : userdata <function>
-- Arguments:
--   f - function
-- Returns:
--   Function f wrapped in a Python object
python.wrap = python.eval("lambda f: lambda *args: f(*args)")

-- python.list(...) : userdata <list>
-- Arguments:
--   ... - list items
-- Returns:
--   Python list containing all arguments
-- Example:
--   python.list(1, 2, 3) -> [1, 2, 3]
python.list = bindcontainer('list', 'append')

-- python.tuple(...) : userdata <tuple>
-- Arguments:
--   ... - tuple items
-- Returns:
--   Python tuple containing all arguments
-- Example:
--   python.tuple(4, 5, 6) -> (4, 5, 6)
python.tuple = function(...)
	local l = python.list(...)
	return python.builtins.tuple(l)
end

-- python.set(...) : userdata <set>
-- Arguments:
--   ... - set items
-- Returns:
--   Python set containing all arguments
-- Example:
--   python.set(4, 4, 1) -> {1, 4}
python.set = bindcontainer('set', 'add') 

-- python.dict(...) : userdata <dict>
-- Arguments:
--   ... - dictionary entries (key, values)
-- Returns:
--   Python dictionary containing all arguments
-- Example:
--   python.dict('a', 10, 'b') -> {'a': 10, 'b': None}
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

-- python.import(modulename)
-- Arguments:
--   modulename - module name : string
-- Example:
--   python.import('math')
python.import = function(modulename)
	python.exec("import " .. modulename)
end

-- python._(modulename) : userdata <module>
-- Arguments:
--   modulename - module name : string
-- Returns:
--   Python resolved module or submodule
-- Example:
--   python._('matplotlib.pyplot')
-- Observation:
--   Modules are cached in a weak table
python._ = {}
setmetatable(python._, {
	__mode = "v",
	__index = function(t, modulename)
		local module = python.builtins.__import__(modulename)
		for submodule in modulename:gmatch('%.([^.]+)') do
			module = module[submodule]
		end
		t[modulename] = module
		return module
	end,
})

-----------------------------------------
-- Return module
-----------------------------------------

return python
