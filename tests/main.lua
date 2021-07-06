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

-- Checks if the 'pyobj' (Python object) is an instance
-- of at least one of the types listed after (strings)
local function isinstance(pyobj, ...)
	local pybuiltins = python.builtins
	local pyhasattr = pybuiltins.hasattr
	local pyisinstance = pybuiltins.isinstance
	for _, pytype in ipairs{...} do
		if pyhasattr(pybuiltins, pytype) then
			local pytypeobj = pybuiltins[pytype]
			if pyisinstance(pyobj, pytypeobj) then
				return true
			end
		end
	end
	return false
end

-- Run function f and except it to raise a Python exception
-- that is an instance of the exctype class
local function testerror(exc_type_expected, f, ...)
	local exc_type_before, exc_obj_before = python.exc_info()
	local ok = pcall(f, ...)
	local exc_type_after, exc_obj_after = python.exc_info()
	assert(not ok, "Expected function to raise an error")
	assert(exc_obj_before ~= exc_obj_after, "Expected a new error to be registered")
	assert(python.builtins.isinstance(exc_obj_after, exc_type_expected),
		string.format("Expected to throw %s, not %s", tostring(exc_type_expected), tostring(exc_type_after)))
	return python.as_attrgetter(exc_obj_after)
end

-- Try evaluating 'number' (a string) and expect an OverflowError
-- to be raised by Python. Returns the exception object
local function testoverflow(number)
	return testerror(python.builtins.OverflowError, python.eval, number)
end

-- Run as many garbage collection cycles as needed to
-- stabilize the total space allocated by Lua
-- (Actually does up to 100 cycles, then aborts)
-- Returns the total allocated size
local function collectallgarbage()
	local count = collectgarbage('count')
	for i = 1, 100 do
		collectgarbage('collect')
		local newcount = collectgarbage('count')
		if count == newcount then
			return newcount
		end
		count = newcount
	end
	error "Exceeded limit of garbage collection cycles"
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
	local l_attrs = python.as_attrgetter(l)

	-- Since list implements the sequence protocol, lupa
	-- by default assumes item getter protocol in Python
	testerror(python.builtins.TypeError, function() return l.append end)

	-- By using the as_attrgetter, lupa understands that
	-- any indexation is in fact access to an attribute
	l_attrs.append(0)

	-- Check the effect of calling the append function
	assert(l_attrs.__len__() == 1)
end

function main.AsAttributeGetter_Dict()
	local d = python.dict()
	local d_attrs = python.as_attrgetter(d)

	-- Since dict implements the sequence protocol, lupa
	-- by default assumes item getter protocol in Python
	testerror(python.builtins.KeyError, function() return d.get end)

	-- By using the as_attrgetter, lupa understands that
	-- any indexation is in fact access to an attribute
	assert(d_attrs.get("key", python.none) == nil)

	-- Insert an entry to the dictionary by using the
	-- traditional brackets notation
	d["key"] = "value"
	assert(d_attrs.get("key", python.none) == "value")

	-- Test another form of indextation, using the dot notation
	d.key1 = "value1"
	assert(d_attrs.get("key1", python.none) == "value1")
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
	local l_attrs = python.as_attrgetter(l)

	-- Since list implements the sequence protocol, lupa
	-- by default assumes item getter protocol in Python
	-- But the list is empty so it will fail
	testerror(python.builtins.IndexError, function() return l[0] end)

	-- Populate the list with numbers in order
	for i = 0, 10 do
		l_attrs.append(i)
	end

	-- Using the brackets notation
	for i = 0, 10 do
		-- Check that the items were added
		-- Remember that Python indexation begins with 0
		assert(l[i] == i)
	end

	-- Using python.as_itemgetter
	local l_items = python.as_itemgetter(l_attrs)
	for i = 0, 10 do
		-- Check that the items were added
		-- Remember that Python indexation begins with 0
		assert(l_items[i] == i)
	end
end

function main.AsItemGetter_Dict()
	local d = python.dict()
	local d_attrs = python.as_attrgetter(d)
	local d_items = python.as_itemgetter(d_attrs)

	-- Since dict implements the sequence protocol, lupa
	-- by default assumes item getter protocol in Python
	-- But the dict is empty so it will fail
	testerror(python.builtins.KeyError, function() return d['key'] end)

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
		assert(d_items[i] == i)
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
	testerror(python.builtins.AssertionError, python.exec, "assert False")
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
	testerror(python.builtins.SyntaxError, python.exec, "return")
end

function main.ExecYield()
	testerror(python.builtins.SyntaxError, python.exec, "yield")
end

function main.ExecRaise()
	testerror(python.builtins.RuntimeError, python.exec, "raise RuntimeError")
end

function main.ExecBreak()
	testerror(python.builtins.SyntaxError, python.exec, "break")
end

function main.ExecContinue()
	testerror(python.builtins.SyntaxError, python.exec, "continue")
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
	testerror(python.builtins.SyntaxError, python.exec, "nonlocal " .. varname)
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

function main.CallPyFunction()
	local returnall = python.eval("lambda *args: args")
	local t = {}
	for i = 1, 1000 do
		t[i] = i
	end
	local ret = returnall(table.unpack(t))
	assert(python.builtins.len(ret) == 1000)
	for i = 1, 1000 do
		assert(ret[i-1] == i)
	end
end

function main.Callback()
	local cb_called = false
	local function lua_cb() cb_called = true end
	local python_cb = python.wrap(lua_cb)

	assert(not cb_called)
	python_cb()
	assert(cb_called)

	local function returnalot(n)
		local t = {}
		for i = 1, n do
			t[i] = i
		end
		return table.unpack(t)
	end
	local callme = python.eval("lambda f, *args: f(*args)")
	local ret = callme(returnalot, 1000)
	assert(python.builtins.len(ret) == 1000)
	for i = 1, 1000 do
		assert(ret[i-1] == i)
	end
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
	local isinteger = function(o) return isinstance(o, 'int', 'long') end
	local isfloat = function(o) return isinstance(o, 'float') end

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

	-- Make sure overflows are not ignored
	python.set_overflow_handler(function() error() end)

	-- 10^500 >> 2^63 - 1 (signed 64-bit integer maximum value)
	-- 10^500 >> 1.8*10^308 (double-precision floating-point format maximum value)
	testoverflow('10**500')

	-- -10^500 << -2^63 (signed 64-bit integer minimum value)
	-- -10^500 << -1.8*10^308 (double-precision floating-point format minimum value)
	testoverflow('-10**500')
end

function main.NoHandler()
	python.set_overflow_handler(nil)
	local proxy = python.eval('10**500')
	local proxytype = python.builtins.type(proxy)
	assert(proxytype == python.builtins.int or
	       proxytype == python.builtins.long)
	local proxystr = python.builtins.str(proxy)
	local expectedstr = '1' .. string.rep('0', 500)
	assert(proxystr == expectedstr)
end

function main.EmptyHandler()
	python.set_overflow_handler(function() end)
	assert(python.eval('10**500') == nil)
end

function main.HandlerWithLuaError()
	python.set_overflow_handler(function() error() end)
	testoverflow('2**64')
	testoverflow('10**500')
end

function main.FloatFallbackHandler()
	python.set_overflow_handler(python.builtins.float)
	assert(python.eval('2**64') == 2^64)
	testoverflow('10**500')
end

function main.GarbageCollector()
	-- Test garbage collection, by making sure that the
	-- amount of memory used by Lua before and after calling f
	-- stays the same (that is, all garbage is collected)
	local function testgc(f)
		local count = collectallgarbage()
		for i = 1, 100 do
			f()
			local newcount = collectallgarbage()
			if newcount == count then
				return
			end
			count = newcount
		end
		error(count*1024 .. " bytes leaked")
	end

	testgc(function() end)	
	testgc(function() python.list() end)
	testgc(function() local l = python.list() end)
	testgc(function() python.eval('lua.eval("{}")') end)
	testgc(function() local t = { python.list() } end)
	testgc(function()
		local d = python.dict()
		d.ref = d
	end)
	testgc(function()
		local t = { dict = python.dict() }
		t.dict.ref = t
		setmetatable(t, {__mode = "v"})
	end)
end

function main.ExceptionMessage()
	local exc = testerror(python.builtins.Exception, python.exec, 'raise Exception("xyz")')
	assert(exc.__str__() == 'xyz')
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
		
		if type(f) == 'userdata' then
			local exc = testerror(python.builtins.ReferenceError, f, t.obj)
			assert(exc.__str__() == 'deleted python object')
		else
			assert(type(f) == 'function')
			local ok, ret = pcall(f, t.obj)
			assert(not ok and ret:find('deleted python object'))
		end
	end

	testmissingref(python.dict(), print)                                                -- __tostring
	testmissingref(python.dict(), function(o) print(o[1]) end)                          -- __index
	testmissingref(python.dict(), function(o) print(python.as_itemgetter(o)[1]) end)    -- __index (itemgetter)
	testmissingref(python.dict(), function(o) print(python.as_attrgetter(o).items) end) -- __index (attrgetter)
	testmissingref(python.dict(), function(o) o[1] = 1 end)                             -- __newindex
	testmissingref(python.dict(), function(o) python.as_itemgetter(o)[1] = 1 end)       -- __newindex (itemgetter)
	testmissingref(python.wrap(print), function(o) python.as_attrgetter(o).a = 1 end)   -- __newindex (attrgetter)
	testmissingref(python.wrap(print), function(o) o() end)                             -- __call

	testmissingref(python.dict(), python.builtins.len)   -- call from Python
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
	testtableiterable{[{}]=10}
	testtableiterable{[function() end]=10}
	testtableiterable{[coroutine.create(function() end)]=10}
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

	-- Tests python.args to throw a Lua error and match regex
	local function testpyargs_luaerror(regex, ...)
		local ok, err = pcall(python.args, ...)
		assert(not ok, "expected error")
		assert(type(err) == 'string', "expected string error")
		assert(err:find(regex), "expected regex to match")
	end
	
	-- Tests python.args to throw a Python exception and match regex
	local function testpyargs_pyerror(exctype, regex, ...)
		local exc = testerror(exctype, python.args, ...)
		local msg = exc.__str__()
		assert(msg:find(regex), "expected regex to match")
	end

	testpyargs({}, {})
	testpyargs({}, {}, python.args{})
	testpyargs_luaerror("table expected, got no value")
	testpyargs_luaerror("table expected, got number", 1)
	testpyargs_pyerror(python.builtins.IndexError, "table index out of range", {[0]=7})
	testpyargs_pyerror(python.builtins.IndexError, "table index out of range", {[2]=7})
	testpyargs_pyerror(python.builtins.TypeError, "table key is neither an integer nor a string", {[true]=7})
	testpyargs({1}, {}, python.args{1})
	testpyargs({1, 2, 3}, {}, python.args{1, 2, 3})
	testpyargs({}, {a=1}, python.args{a=1})
	testpyargs({}, {a=1, b=2, c=3}, python.args{a=1, b=2, c=3})
	testpyargs({1}, {a=1}, python.args{a=1, 1})
	testpyargs({1}, {a=1, b=2, c=3}, python.args{a=1, b=2, c=3, 1})
	testpyargs({1, 2, 3}, {a=1}, python.args{a=1, 1, 2, 3})
	testpyargs({1, 2, 3}, {a=1, b=2, c=3}, python.args{a=1, b=2, c=3, 1, 2, 3})
end

function main.ReloadLibrary()
	local lib1 = python
	package.loaded.lupafromlua = nil
	local lib2 = require "lupafromlua"
	assert(lib1 == lib2, "not the same library")
end

return main
