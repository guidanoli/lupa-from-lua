-----------------------------------------------------------
-- Tests the lupafromlua Lua C
-- Run from the project root directory
-----------------------------------------------------------

local utils = require "tests.utils"
local python = require "tests.lupa"

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

-- Set current overflow handler
local function setoverflowhandler(f)
	lupa_overflow_cb = f
end

-- Test the handling of overflow when trying to fit an overly
-- big Python long into a Lua number (potentially an integer).
-- You can either expect that an error will be raised (success=false)
-- or that it will succeed (success=true)
-- If it succeeds, returns the converted object
-- If it fails, returns the error message
local function testoverflow(success)
	local ok, ret = pcall(python.eval, '10**500')
	assert(ok == success, tostring(ret) .. "\n" .. debug.traceback())
	return ret
end

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
	error(count*1024 .. " bytes leaked\n" .. debug.traceback())
end

-- Test if tables can have finalizers
local tableshavegc = false
setmetatable({}, {__gc = function() tableshavegc = true end})
collectgarbage()

-----------------------------------------------------------
-- Test cases
-----------------------------------------------------------

local Testbench = {}

function Testbench:LuaVersion()
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

function Testbench:AsAttributeGetter_List()
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

function Testbench:AsAttributeGetter_Dict()
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

function Testbench:AsAttributeGetter_Builtins()
	local builtins = python.builtins
	-- Since builtins is a module, it does not implement the
	-- sequence protocol, which means that by default, lupa
	-- assumes attribute getter protocol in Python
	local l1 = builtins.list
	local l2 = python.as_attrgetter(builtins).list

	-- Which means that l1 should be equal to l2 in Python
	assert(python.equal(l1,l2))
end

function Testbench:AsItemGetter_List()
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

function Testbench:AsItemGetter_Dict()
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

function Testbench:AsFunction_Eval()
	local eval_asfunction = python.as_function(python.eval)

	-- Even though eval is already a wrapper (userdata),
	-- it should be possible to wrap it one more time
	assert(eval_asfunction("1 + 1") == 2)
end

function Testbench:Eval()
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

function Testbench:ExecAssignment()
	local varname = newname()
	local value = math.random(128)

	python.exec(varname .. " = " .. value)

	assert(python.eval(varname) == value)
end

function Testbench:ExecCall()
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

function Testbench:ExecAssert()
	python.exec("assert True")
	assert(not pcall(function()
		python.exec("assert False")
	end))
end

function Testbench:ExecPass()
	python.exec("pass")
end

function Testbench:ExecAugmentedAssignment()
	local varname = newname()

	python.exec(varname .. " = 321")
	python.exec(varname .. " += 123")
	assert(python.eval(varname) == 444)
end

function Testbench:ExecDel()
	local varname = newname()

	python.exec(varname .. " = { 1:1 }")
	assert(python.equal(python.eval(varname), python.dict(1, 1)))
	python.exec("del " .. varname .. "[1]")
	assert(python.equal(python.eval(varname), python.dict()))
end

function Testbench:ExecReturn()
	assert(not pcall(function()
		python.exec("return")
	end))
end

function Testbench:ExecYield()
	assert(not pcall(function()
		python.exec("yield")
	end))
end

function Testbench:ExecRaise()
	assert(not pcall(function()
		python.exec("raise RuntimeError")
	end))
end

function Testbench:ExecBreak()
	assert(not pcall(function()
		python.exec("break")
	end))
end

function Testbench:ExecContinue()
	assert(not pcall(function()
		python.exec("continue")
	end))
end

function Testbench:ExecImport()
	local alias = newname()

	python.exec("import lupa")
	python.exec("from lupa import LuaRuntime as " .. alias)
end

function Testbench:ExecGlobal()
	local varname = newname()

	python.exec("global " .. varname)
end

function Testbench:ExecNonLocal()
	local varname = newname()

	assert(not pcall(function()
		python.exec("nonlocal " .. varname)
	end))
end

function Testbench:IterList()
	local l = python.list(1, 2, 3)
	local i = 1
	for li in python.iter(l) do
		assert(li == i)
		i = i + 1
	end
end

function Testbench:IterDict()
	local d = python.dict("a", 1, "b", 2, "c", 3)
	local t = {a=1, b=2, c=3}
	for di in python.iter(d) do
		assert(d[di] == t[di])
		t[di] = nil
	end
end

function Testbench:IterClass()
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

function Testbench:None()
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

function Testbench:IterEx()
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

function Testbench:Enumerate()
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

function Testbench:Callback()
	local cb_called = false
	local function lua_cb() cb_called = true end
	local python_cb = python.wrap(lua_cb)

	assert(not cb_called)
	python_cb()
	assert(cb_called)
end

function Testbench:Roundtrip()
	local testcases = {
		nil,
		python.none,
		"ação",
		123456789,
		0.125,
		{},
		{ "a", "b", "c" },
		{ a=1, b=2, c=3 },
		self,
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

function Testbench:MultipleReturnValues()
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

function Testbench:NumberFromLuaToPython()
	local eqtype = python.eval('lambda a, b: type(a) is type(eval(b))')
	local eqvalue = python.eval('lambda a, b: a == eval(b)')
	local isnan = python._.math.isnan

	local isint = python.eval('lambda n: type(n) is int')
	local isfloat = python.eval('lambda n: type(n) is float')

	local function roundtrip(num)
		assert(eqtype(num, tostring(num)))
		assert(eqvalue(num, tostring(num)))
	end

	assert(isint(1))
	assert(eqtype(1, '1'))
	assert(eqvalue(1, '1'))
	assert(eqvalue(1.0, '1.0'))
	assert(eqvalue(1.0, '1'))
	assert(eqvalue(1, '1.0'))

	assert(isfloat(1.2))
	assert(eqtype(1.2, '1.2'))
	assert(eqvalue(1.2, '1.2'))

	assert(isfloat(math.pi))
	assert(eqtype(math.pi, 'math.pi'))
	assert(eqvalue(math.pi, 'math.pi'))

	-- According to IEEE 754, a nan value is considered not equal to any value, including itself
	-- So we can't really compare Python and Lua nan's but we can use math.isnan from Python
	assert(isnan(0/0))

	assert(eqvalue(math.huge, 'float("inf")'))
	assert(eqvalue(-math.huge, 'float("-inf")'))

	if hasintegers then
		-- If Lua supports integers, the subtype is preserved
		assert(isfloat(1.0))
		assert(eqtype(1.0, '1.0'))

		assert(isint(math.maxinteger))
		roundtrip(math.maxinteger)

		assert(isint(math.mininteger))
		roundtrip(math.mininteger)
	else
		-- If Lua doesn't support integers, the subtype is
		-- infered by whether the number has a decimal part or not
		assert(isint(1.0))
		assert(eqtype(1.0, '1'))
	end
end

function Testbench:NumberFromPythonToLua()
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
	setoverflowhandler(nil)

	-- 10^500 >> 2^63 - 1 (signed 64-bit integer maximum value)
	-- 10^500 >> 1.8*10^308 (double-precision floating-point format maximum value)
	assert(not pcall(python.eval, '10**500'),
		"Converting too large Python integers should throw an error")
	
	-- -10^500 << 2^64 (signed 64-bit integer minimum value)
	-- -10^500 << -1.8*10^308 (double-precision floating-point format minimum value)
	assert(not pcall(python.eval, '-10**500'),
		"Converting too large Python integers should throw an error")
end

function Testbench:NoHandler()
	setoverflowhandler(nil)
	testoverflow(false)
end

function Testbench:EmptyHandler()
	setoverflowhandler(function() end)
	assert(testoverflow(true) == nil)
end

function Testbench:HandlerWithLuaError()
	setoverflowhandler(function() error() end)
	assert(testoverflow(false))
end

function Testbench:FloatFallbackHandler()
	local python_float = python.eval('float')
	setoverflowhandler(function(o)
		return python_float(o)
	end)
	local ok, ret = pcall(python.eval, '10**100')
	assert(ok, ret)
	utils:TestNumEq(ret, 1e100)
	testoverflow(false)
end

function Testbench:GarbageCollector()
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

function Testbench:ExceptionMessage()
	local ok, ret = pcall(python.exec, 'raise Exception("myerrormessage")')
	assert(not ok, "Python raise should have led to Lua error")
	assert(ret:find("Exception: myerrormessage"), "Error message should be preserved")
end

function Testbench:MissingReference()
	local t

	if tableshavegc then
		t = { d = python.dict() }
		setmetatable(t, {__gc = function(o) t = o end}) 
	elseif newproxy then
		local p = newproxy(true)
		t = getmetatable(p)
		t.d = python.dict()
		t.__gc = function(o) t = getmetatable(o) end
	else
		error("Tables can't have finalizers and newproxy isn't available")
	end

	t = nil
	collectgarbage()
	assert(t ~= nil, "finalizer not called")
	assert(t.d ~= nil, "table graph not restored")
	
	local ok, ret = pcall(function() t.d[1] = 1 end)
	assert(not ok, "Python should raise an error when accessign missing reference")
	assert(ret:find("deleted python object"), "Error message should contain 'deleted python object'")
end

return Testbench
