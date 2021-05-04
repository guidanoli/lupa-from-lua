-----------------------------------------------------------
-- Tests the lupafromlua Lua C
-- Run from the project root directory
-----------------------------------------------------------

local utils = require "tests.utils"
local python = require "tests.python"

-----------------------------------------------------------
-- Python imports
-----------------------------------------------------------

python.import "math"

-----------------------------------------------------------
-- Setup
-----------------------------------------------------------

local names = 0

-- Avoids name collision in Python global scope
local function newname()
	local name = names
	names = names + 1
	return "t" .. name
end

-- Check if current Lua version supports integers
local hasintegers = math.tointeger ~= nil

-- Test the handling of overflow when trying to fit an overly
-- big Python long into a Lua number (potentially an integer).
-- You can either expect that an error will be raised (success=false)
-- or that it will succeed (success=true)
-- If it succeeds, returns the converted object
-- If it fails, returns the error message
local function testoverflow(success)
	local ok, ret = pcall(python.eval, '10**500')
	assert(ok == success, tostring(ret))
	return ret
end

-----------------------------------------------------------
-- Test cases
-----------------------------------------------------------

local main = {}

function main.LuaVersion()
	local lua = python.eval("lua")
	local lupa_lua_version = lua.lua_version

	-- The tuple (MAJOR, MINOR) is returned
	local lupa_lua_major = lupa_lua_version[0]
	local lupa_lua_minor = lupa_lua_version[1]

	local semvernums = {}
	for semvernum in string.gmatch(_VERSION, "%d+") do
		-- The major and minor numbers are extracted
		-- from the _VERSION global variable using gmatch
		table.insert(semvernums, tonumber(semvernum))
	end

	-- Make sure that the version of Lua embedded into
	-- Lupa is the same as the one running this script
	assert(#semvernums >= 2)
	assert(semvernums[1] == lupa_lua_major)
	assert(semvernums[2] == lupa_lua_minor)
end

function main.AsAttributeGetter_List()
	local l = python.list()

	assert(not pcall(function()
		-- Since list implements the sequence protocol, lupa
		-- by default assumes item getter protocol in Python
		return l.append
	end))

	-- By using the as_attrgetter, lupa understands that
	-- any indexation is in fact access to an attribute
	local append_func = python.as_attrgetter(l).append
	append_func(0)

	-- Check the effect of calling the append function
	local len_func = python.as_attrgetter(l).__len__
	assert(len_func() == 1)
end

function main.AsAttributeGetter_Dict()
	local d = python.dict()

	assert(not pcall(function()
		-- Since dict implements the sequence protocol, lupa
		-- by default assumes item getter protocol in Python
		return d.get
	end))

	-- By using the as_attrgetter, lupa understands that
	-- any indexation is in fact access to an attribute
	local get_func = python.as_attrgetter(d).get
	assert(get_func("key", python.none) == nil)

	-- Insert an entry to the dictionary by using the
	-- traditional brackets notation
	d["key"] = "value"
	assert(get_func("key", python.none) == "value")

	-- Test another form of indextation, using the dot notation
	d.key1 = "value1"
	assert(get_func("key1", python.none) == "value1")
end

function main.AsAttributeGetter_Builtins()
	local builtins = python.builtins
	-- Since builtins is a module, it does not implement the
	-- sequence protocol, which means that by default, lupa
	-- assumes attribute getter protocol in Python
	local l1 = builtins.list
	local l2 = python.as_attrgetter(builtins).list

	-- Which means that l1 should be equal to l2 in Python
	assert(python.equal(l1,l2))
end

function main.AsItemGetter_List()
	local l = python.list()

	assert(not pcall(function ()
		-- Since list implements the sequence protocol, lupa
		-- by default assumes item getter protocol in Python

		-- But the list is empty so it will fail
		return l[0]
	end))

	-- Populate the list with numbers in order
	for i = 0, 10 do
		python.as_attrgetter(l).append(i)
	end

	-- Using the brackets notation
	for i = 0, 10 do
		-- Check that the items were added
		-- Remember that Python indexation begins with 0
		assert(l[i] == i)
	end

	-- Using python.as_itemgetter
	for i = 0, 10 do
		-- Check that the items were added
		-- Remember that Python indexation begins with 0
		assert(python.as_itemgetter(l)[i] == i)
	end
end

function main.AsItemGetter_Dict()
	local d = python.dict()

	assert(not pcall(function ()
		-- Since dict implements the sequence protocol, lupa
		-- by default assumes item getter protocol in Python

		-- But the dict is empty so it will fail
		return d["key"]
	end))

	-- Populate the dict with numbers in order
	for i = 0, 10 do
		d[i] = i
	end

	-- Using the brackets notation
	for i = 0, 10 do
		-- Check that the items were added
		assert(d[i] == i)
	end

	-- Using python.as_itemgetter
	for i = 0, 10 do
		-- Check that the items were added
		assert(python.as_itemgetter(d)[i] == i)
	end
end

function main.AsFunction_Eval()
	local eval_asfunction = python.as_function(python.eval)

	-- Even though eval is already a wrapper (userdata),
	-- it should be possible to wrap it one more time
	assert(eval_asfunction("1 + 1") == 2)
end

function main.Eval()
	local testcases = {
		{ "1", 1 },
		{ "1 + 1", 2 },
		{ "2 * 3", 6 },
		{ "10 / 5", 2 },
		{ "2 ** 4", 16 },
		{ "10 % 7", 3 },
		{ "[]", python.list() },
		{ "[1]", python.list(1) },
		{ "[1, 2, 3]", python.list(1, 2, 3) },
		{ "{}", python.dict() },
		{ "{'a': 1}", python.dict("a", 1) },
		{ "{'a': 1, 'b': 2, 'c': 3}", python.dict("a", 1, "b", 2, "c", 3) },
		{ "()", python.tuple() },
		{ "(1, )", python.tuple(1) },
		{ "(1, 2, 3)", python.tuple(1, 2, 3) },
		{ "set()", python.set() },
		{ "{1}", python.set(1) },
		{ "{1}", python.set(1, 1, 1) },
		{ "{1, 2, 3}", python.set(1, 2, 3) },
		{ "{1, 2, 3}", python.set(1, 2, 3, 2, 2, 1) },
		{ "abs(-1)", 1 },
		{ "abs(1)", 1 },
		{ "len([])", 0 },
		{ "len([1])", 1 },
		{ "len([1, 2, 3])", 3 },
		{ "len({})", 0 },
		{ "len({1:1})", 1 },
		{ "len({1:1, 2:2, 3:3})", 3 },
		{ "max([1, 2, 3, -1])", 3 },
		{ "min([1, 2, 3, -1])", -1 },
		{ "next(iter([1, 2, 3, -1]))", 1 },
		{ "sorted([1, -5, 3, -1])", python.list(-5, -1, 1, 3) },
		{ "sum([1, -5, 3, -1])", -2 },
		{ "None", python.none },
		{ "None", nil },
		{ "False", false },
		{ "True", true },
		{ "(lambda x: x*2)(10)", 20 },
		{ "(lambda x: x*2)([1, 2, 3])", python.list(1, 2, 3, 1, 2, 3) },
		{ "''", "" },
		{ "'ascii'", "ascii" },
		{ "'ação'", "ação" },
		{ "u''", "" },
		{ "u'ação'", "ação" },
		{ "'\\n\\t'", "\n\t" },
	}

	for testindex, testcase in ipairs(testcases) do
		local input, output = table.unpack(testcase)
		local ok, ret = pcall(python.eval, input)
		if not ok then
			error("failed test #" .. testindex .. ": " .. tostring(ret))
		end
		if not python.equal(output, ret) then
			error("failed test #" .. testindex .. ": obtained " .. tostring(ret))
		end
	end
end

function main.ExecAssignment()
	local varname = newname()
	local value = math.random(128)

	python.exec(varname .. " = " .. value)

	assert(python.eval(varname) == value)
end

function main.ExecCall()
	local funcname = newname()
	local varname = newname()
	local paramname = newname()
	local value = math.random(128)

	python.exec(varname .. " = None")
	python.exec("def " .. funcname .. "(" .. paramname .. "):\n" ..
		"\tglobal " .. varname .. "\n" ..
		"\t" .. varname .. " = " .. paramname)
	python.exec(funcname .. "(" .. value .. ")")

	assert(python.eval(varname) == value)
end

function main.ExecAssert()
	python.exec("assert True")
	assert(not pcall(function()
		python.exec("assert False")
	end))
end

function main.ExecPass()
	python.exec("pass")
end

function main.ExecAugmentedAssignment()
	local varname = newname()

	python.exec(varname .. " = 321")
	python.exec(varname .. " += 123")
	assert(python.eval(varname) == 444)
end

function main.ExecDel()
	local varname = newname()

	python.exec(varname .. " = { 1:1 }")
	assert(python.equal(python.eval(varname), python.dict(1, 1)))
	python.exec("del " .. varname .. "[1]")
	assert(python.equal(python.eval(varname), python.dict()))
end

function main.ExecReturn()
	assert(not pcall(function()
		python.exec("return")
	end))
end

function main.ExecYield()
	assert(not pcall(function()
		python.exec("yield")
	end))
end

function main.ExecRaise()
	assert(not pcall(function()
		python.exec("raise RuntimeError")
	end))
end

function main.ExecBreak()
	assert(not pcall(function()
		python.exec("break")
	end))
end

function main.ExecContinue()
	assert(not pcall(function()
		python.exec("continue")
	end))
end

function main.ExecImport()
	local alias = newname()

	python.exec("import lupa")
	python.exec("from lupa import LuaRuntime as " .. alias)
end

function main.ExecGlobal()
	local varname = newname()

	python.exec("global " .. varname)
end

function main.ExecNonLocal()
	local varname = newname()

	assert(not pcall(function()
		python.exec("nonlocal " .. varname)
	end))
end

function main.IterList()
	local l = python.list(1, 2, 3)
	local i = 1
	for li in python.iter(l) do
		assert(li == i)
		i = i + 1
	end
end

function main.IterDict()
	local d = python.dict("a", 1, "b", 2, "c", 3)
	local t = {a=1, b=2, c=3}
	for di in python.iter(d) do
		assert(d[di] == t[di])
		t[di] = nil
	end
end

function main.IterClass()
	local classname = newname()

	python.exec("class " .. classname .. ":\n" ..
		"\tdef __init__(self, obj):\n" ..
		"\t\tself.obj = obj\n" ..
		"\tdef __iter__(self):\n" ..
		"\t\treturn iter(self.obj)")

	local l = python.list(1, 2, 3)
	local instance = python.eval(classname)(l)

	local i = 1
	for ci in python.iter(instance) do
		assert(ci == i)
		i = i + 1
	end
end

function main.None()
	assert(python.equal(python.none, nil))
	assert(tostring(python.none) == "None")
	assert(python.builtins.str(python.none) == "None")
	assert(python.builtins.str(nil) == "None")
	assert(python.none)
	assert(python.none ~= nil)

	local d = python.dict(nil, nil)

	local entered = false
	for di in python.iter(d) do
		assert(di == python.none)
		entered = true
	end
	assert(entered)

	entered = false
	for k, v in python.iterex(python.as_attrgetter(d).items()) do
		assert(k == python.none)
		assert(v == nil)
		entered = true
	end
	assert(entered)

	local l = python.list(nil, nil)
	entered = false
	for li in python.iter(l) do
		assert(li == python.none)
		entered = true
	end
	assert(entered)
end

function main.IterEx()
	local d = python.dict("a", 1, "b", 2, "c", 3)
	local t = {a=1, b=2, c=3}
	local d_items = python.as_attrgetter(d).items()

	for key, value in python.iterex(d_items) do
		assert(t[key] == value)
		t[key] = nil
	end

	local generatorname = newname()
	python.exec("def " .. generatorname .. "(n):\n" ..
		"\tfor i in range(n):\n" ..
		"\t\tyield i, -i, 2*i, i*i")

	local n = 10
	local g = python.eval(generatorname .. "(" .. n .. ")")

	i = 0
	for a, b, c, d in python.iterex(g) do
		assert(a == i)
		assert(b == -i)
		assert(c == 2*i)
		assert(d == i*i)
		i = i + 1
	end
end

function main.Enumerate()
	local l, entered

	l = python.list(0, 1, 2, 3)
	entered = false
	for i, li in python.enumerate(l) do
		assert(i == li)
		entered = true
	end
	assert(entered)

	l = python.list()
	entered = false
	for i, li in python.enumerate(l) do
		entered = true
	end
	assert(not entered)
end

function main.Callback()
	local cb_called = false
	local function lua_cb() cb_called = true end
	local python_cb = python.wrap(lua_cb)

	assert(not cb_called)
	python_cb()
	assert(cb_called)
end

function main.Roundtrip()
	local testcases = {
		nil,
		python.none,
		"ação",
		123456789,
		0.125,
		{},
		{ "a", "b", "c" },
		{ a=1, b=2, c=3 },
		main,
		function () return 42 end,
		coroutine.create(function () return 42 end),
	}

	for testindex, testcase in ipairs(testcases) do
		local python_cb = python.wrap(function() return testcase end)
		local ok, ret = pcall(python_cb)
		if not ok then
			error("failed test #" .. testindex .. ": " .. tostring(ret))
		end
		if ret ~= testcase then
			error("failed test #" .. testindex .. ": obtained " .. tostring(ret))
		end
	end
end

function main.MultipleReturnValues()
	local testcases = {
		{
			input = { "a", "b", "c" },
			output = python.tuple("a", "b", "c")
		},
		{
			input = { "a", "b", nil, "c" },
			output = python.tuple("a", "b", nil, "c"),
		},
		{
			input = { "a", "b", nil }, -- nil is ignored in Lua
			output = python.tuple("a", "b"),
		},
		{
			input = { "a", "b", python.none },
			output = python.tuple("a", "b", python.none),
		},
		{
			input = { "a", "b", nil, python.none }, -- nil is no longer ignored
			output = python.tuple("a", "b", python.none, python.none),
		},
	}

	local identity = python.wrap(function(...) return ... end)

	for testindex, testcase in ipairs(testcases) do
		local ok, ret = pcall(identity, table.unpack(testcase.input))
		if not ok then
			error("failed test #" .. testindex .. ": " .. tostring(ret))
		end
		if not python.equal(ret, testcase.output) then
			error("failed test #" .. testindex .. ": obtained " .. tostring(ret))
		end
	end
	
end

function main.NumberFromLuaToPython()
	local eqvalue = python.eval('lambda a, b: a == eval(b)')
	local eqvalueself = function(o) return eqvalue(o, tostring(o)) end
	local isnan = python._.math.isnan
	local isinteger
	if pcall(python.eval, 'long') then
		isinteger = python.eval('lambda n: isinstance(n, (int, long))')
	else
		isinteger = python.eval('lambda n: isinstance(n, int)')
	end
	local isfloat = python.eval('lambda n: isinstance(n, float)')

	assert(isinteger(1))
	assert(eqvalue(1, '1'))
	assert(eqvalue(1.0, '1.0'))
	assert(eqvalue(1.0, '1'))
	assert(eqvalue(1, '1.0'))

	assert(isfloat(1.2))
	assert(eqvalue(1.2, '1.2'))

	assert(isfloat(math.pi))
	assert(eqvalue(math.pi, 'math.pi'))

	-- According to IEEE 754, a nan value is considered not equal to any value, including itself
	-- So we can't really compare Python and Lua nan's but we can use math.isnan from Python
	assert(isnan(0/0))

	assert(eqvalue(math.huge, 'float("inf")'))
	assert(eqvalue(-math.huge, 'float("-inf")'))

	if hasintegers then
		-- If Lua supports integers, the subtype is preserved
		assert(isfloat(1.0))

		assert(isinteger(math.maxinteger))
		assert(eqvalueself(math.maxinteger))

		assert(isinteger(math.mininteger))
		assert(eqvalueself(math.mininteger))
	else
		-- If Lua doesn't support integers, the subtype is
		-- infered by whether the number has a decimal part or not
		assert(isinteger(1.0))
	end
end

function main.NumberFromPythonToLua()
	utils:TestNumEq(python.eval('1'), 1)
	utils:TestNumEq(python.eval('1.0'), 1.0)
	utils:TestNumEq(python.eval('math.pi'), math.pi)

	-- According to IEEE 754, a nan value is considered not equal to any value, including itself
	-- So we can't really compare Python and Lua nan's but we can compare Python nan to itself and
	-- except that the comparison will return false
	local nan = python.eval('float("nan")')
	utils:TestMathTypeEq(nan, 0/0)
	assert(nan ~= nan, "Python nan converted to Lua is not nan")

	utils:TestNumEq(python.eval('float("inf")'), 1/0)
	utils:TestNumEq(python.eval('float("-inf")'), -1/0)

	-- Make sure no overflow handler is set
	python.set_overflow_handler(nil)

	-- 10^500 >> 2^63 - 1 (signed 64-bit integer maximum value)
	-- 10^500 >> 1.8*10^308 (double-precision floating-point format maximum value)
	assert(not pcall(python.eval, '10**500'),
		"Converting too large Python integers should throw an error")
	
	-- -10^500 << 2^64 (signed 64-bit integer minimum value)
	-- -10^500 << -1.8*10^308 (double-precision floating-point format minimum value)
	assert(not pcall(python.eval, '-10**500'),
		"Converting too large Python integers should throw an error")
end

function main.NoHandler()
	python.set_overflow_handler(nil)
	testoverflow(false)
end

function main.EmptyHandler()
	python.set_overflow_handler(function() end)
	assert(testoverflow(true) == nil)
end

function main.HandlerWithLuaError()
	python.set_overflow_handler(error)
	assert(testoverflow(false))
end

function main.FloatFallbackHandler()
	python.set_overflow_handler(python.builtins.float)
	local ok, ret = pcall(python.eval, '10**100')
	assert(ok, ret)
	utils:TestNumEq(ret, 1e100)
	testoverflow(false)
end

function main.GarbageCollector()
	-- Test garbage collection, by making sure that the
	-- amount of memory used by Lua before and after calling f
	-- stays the same (that is, all is garbage collected)
	local function testgc(f)
		local count
		for i = 1, 100 do
			collectgarbage()
			collectgarbage()
			count = collectgarbage('count')
			f()
			collectgarbage()
			collectgarbage()
			count = collectgarbage('count') - count
			if count == 0 then
				return
			end
		end
		error(count*1024 .. " bytes leaked")
	end

	testgc(function() end)	
	testgc(function() python.list() end)
	testgc(function() local l = python.list() end)
	testgc(function() local t = { python.list() } end)
	testgc(function()
		local d = python.dict()
		d.ref = d
	end)
	testgc(function()
		local t = { dict = python.dict() }
		setmetatable(t, {__mode = "v"})
		t.dict.ref = t
	end)
end

function main.ExceptionMessage()
	local ok, ret = pcall(python.exec, 'raise Exception("myerrormessage")')
	assert(not ok, "Python raise should have led to Lua error")
	assert(ret:find("Exception: myerrormessage"), "Error message should be preserved")
end

function main.MissingReference()
	-- Test if tables can have finalizers
	local tableshavegc = false
	setmetatable({}, {__gc = function() tableshavegc = true end})
	collectgarbage()

	-- Tests missing reference, by making sure that an error
	-- containing 'deleted python object' is raised when calling
	-- f with a missing reference in userdata 'obj'
	-- Observation: make sure obj is not referenced anywhere else
	local function testmissingref(obj, f)
		local t
		if tableshavegc then
			t = { obj = obj }
			setmetatable(t, {__gc = function(t_) t = t_ end}) 
		elseif newproxy then
			local p = newproxy(true)
			t = getmetatable(p)
			t.obj = obj
			t.__gc = function(p_) t = getmetatable(p_) end
		else
			error("tables can't have finalizers and newproxy isn't available")
		end

		obj = nil
		t = nil
		collectgarbage()
		assert(t ~= nil, "finalizer not called")
		assert(t.obj ~= nil, "table graph not restored")
		
		local ok, ret = pcall(f, t.obj)
		assert(not ok, "Python should raise an error when accessign missing reference")
		assert(ret:find("deleted python object"), "Error message should contain 'deleted python object'")
	end

	testmissingref(python.dict(), print)                                                -- __tostring
	testmissingref(python.dict(), function(o) print(o[1]) end)                          -- __index
	testmissingref(python.dict(), function(o) print(python.as_itemgetter(o)[1]) end)    -- __index (itemgetter)
	testmissingref(python.dict(), function(o) print(python.as_attrgetter(o).items) end) -- __index (attrgetter)
	testmissingref(python.dict(), function(o) o[1] = 1 end)                             -- __newindex
	testmissingref(python.dict(), function(o) python.as_itemgetter(o)[1] = 1 end)       -- __newindex (itemgetter)
	testmissingref(python.wrap(print), function(o) python.as_attrgetter(o).a = 1 end)   -- __newindex (attrgetter)
	testmissingref(python.wrap(print), function(o) o() end)                             -- __call

	testmissingref(python.dict(), python.builtins.print) -- reflection
	testmissingref(python.dict(), python.iter)           -- iteration
	testmissingref(python.dict(), python.iterex)         -- iteration (explode tuples)
	testmissingref(python.dict(), python.enumerate)      -- iteration (with indices)
	testmissingref(python.dict(), python.as_function)    -- cast to function
	testmissingref(python.dict(), python.as_itemgetter)  -- item getter protocol
	testmissingref(python.dict(), python.as_attrgetter)  -- attribute getter protocol
end

function main.LuaTableIterable()
	-- Tests table as iterable in Python
	-- Calls python.builtins.dict with t
	-- and checks if dictionary matches table
	local function testtableiterable(t)
		d = python.builtins.dict(t)
		dsize = 0
		for key in python.iter(d) do
			dsize = dsize + 1
		end
		tsize = 0
		for key in pairs(t) do
			tsize = tsize + 1
		end
		assert(dsize == tsize)
		for key, tvalue in pairs(t) do
			dvalue = d[key]
			assert(dvalue == tvalue)
		end
	end

	testtableiterable{}
	testtableiterable{1}
	testtableiterable{1, 2, 3}
	testtableiterable{a=1}
	testtableiterable{a=1, b=2, c=3}
	testtableiterable{a=1, 1}
	testtableiterable{a=1, b=2, c=3, 1}
	testtableiterable{a=1, 1, 2, 3}
	testtableiterable{a=1, b=2, c=3, 1, 2, 3}
	testtableiterable{["with spaces"]=10}
	testtableiterable{[""]=10}
	testtableiterable{[1.2]=10}
	-- testtableiterable{[{}]=10} FIXME
	-- testtableiterable{[function() end]=10} FIXME
	-- testtableiterable{[coroutine.create(function() end)]=10} FIXME
end

function main.PythonArguments()
	-- Identity function
	local identity = python.eval("lambda *args, **kwargs: (args, kwargs)")

	-- Tests Python arguments
	-- Calls the identity function with ...
	-- and checks if args and kwargs match
	local function testpyargs(args, kwargs, ...)
		local ret = identity(...)
		local retargs = ret[0]
		local retkwargs = ret[1]
		assert(#args == python.builtins.len(retargs))
		for i, arg in ipairs(args) do
			assert(retargs[i-1] == arg)
		end
		for key, value in pairs(kwargs) do
			assert(retkwargs[key] == value)
		end
		local items = python.as_attrgetter(retkwargs).items()
		for key, value in python.iterex(items) do
			assert(kwargs[key] == value)
		end
	end

	-- Tests testpyargs error message against regex
	local function testpyargserror(regex, ...)
		local ok, ret = pcall(python.args, ...)
		assert(not ok)
		assert(type(ret) == 'string')
		assert(ret:find(regex))
	end

	testpyargs({}, {})
	testpyargs({}, {}, python.args{})
	testpyargserror("table expected, got no value")
	testpyargserror("table expected, got number", 1)
	testpyargserror("table index out of range", {[3]=7})
	testpyargserror("table key is neither an integer nor a string", {[{}]=7})
	testpyargs({1}, {}, python.args{1})
	testpyargs({1, 2, 3}, {}, python.args{1, 2, 3})
	testpyargs({}, {a=1}, python.args{a=1})
	testpyargs({}, {a=1, b=2, c=3}, python.args{a=1, b=2, c=3})
	testpyargs({1}, {a=1}, python.args{a=1, 1})
	testpyargs({1}, {a=1, b=2, c=3}, python.args{a=1, b=2, c=3, 1})
	testpyargs({1, 2, 3}, {a=1}, python.args{a=1, 1, 2, 3})
	testpyargs({1, 2, 3}, {a=1, b=2, c=3}, python.args{a=1, b=2, c=3, 1, 2, 3})
end

return main
