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
local newname = function()
	local name = names
	names = names + 1
	return "t" .. name
end

-- Check if current Lua version supports integers
local hasintegers = math.tointeger ~= nil

-----------------------------------------------------------
-- Test cases
-----------------------------------------------------------

local Testbench = {
	name = "lupafromlua",
}

function Testbench:TestLuaVersion()
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

function Testbench:TestAsAttributeGetter_List()
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

function Testbench:TestAsAttributeGetter_Dict()
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

function Testbench:TestAsAttributeGetter_Builtins()
	local builtins = python.builtins
	-- Since builtins is a module, it does not implement the
	-- sequence protocol, which means that by default, lupa
	-- assumes attribute getter protocol in Python
	local l1 = builtins.list
	local l2 = python.as_attrgetter(builtins).list

	-- Which means that l1 should be equal to l2 in Python
	assert(python.equal(l1,l2))
end

function Testbench:TestAsItemGetter_List()
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

function Testbench:TestAsItemGetter_Dict()
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

function Testbench:TestAsFunction_Eval()
	local eval_asfunction = python.as_function(python.eval)

	-- Even though eval is already a wrapper (userdata),
	-- it should be possible to wrap it one more time
	assert(eval_asfunction("1 + 1") == 2)
end

function Testbench:TestEval()
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

function Testbench:TestExecAssignment()
	local varname = newname()
	local value = math.random(128)

	python.exec(varname .. " = " .. value)

	assert(python.eval(varname) == value)
end

function Testbench:TestExecCall()
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

function Testbench:TestExecAssert()
	python.exec("assert True")
	assert(not pcall(function()
		python.exec("assert False")
	end))
end

function Testbench:TestExecPass()
	python.exec("pass")
end

function Testbench:TestExecAugmentedAssignment()
	local varname = newname()

	python.exec(varname .. " = 321")
	python.exec(varname .. " += 123")
	assert(python.eval(varname) == 444)
end

function Testbench:TestExecDel()
	local varname = newname()

	python.exec(varname .. " = { 1:1 }")
	assert(python.equal(python.eval(varname), python.dict(1, 1)))
	python.exec("del " .. varname .. "[1]")
	assert(python.equal(python.eval(varname), python.dict()))
end

function Testbench:TestExecReturn()
	assert(not pcall(function()
		python.exec("return")
	end))
end

function Testbench:TestExecYield()
	assert(not pcall(function()
		python.exec("yield")
	end))
end

function Testbench:TestExecRaise()
	assert(not pcall(function()
		python.exec("raise RuntimeError")
	end))
end

function Testbench:TestExecBreak()
	assert(not pcall(function()
		python.exec("break")
	end))
end

function Testbench:TestExecContinue()
	assert(not pcall(function()
		python.exec("continue")
	end))
end

function Testbench:TestExecImport()
	local alias = newname()

	python.exec("import lupa")
	python.exec("from lupa import LuaRuntime as " .. alias)
end

function Testbench:TestExecGlobal()
	local varname = newname()

	python.exec("global " .. varname)
end

function Testbench:TestExecNonLocal()
	local varname = newname()

	assert(not pcall(function()
		python.exec("nonlocal " .. varname)
	end))
end

function Testbench:TestIterList()
	local l = python.list(1, 2, 3)
	local i = 1
	for li in python.iter(l) do
		assert(li == i)
		i = i + 1
	end
end

function Testbench:TestIterDict()
	local d = python.dict("a", 1, "b", 2, "c", 3)
	local t = {a=1, b=2, c=3}
	for di in python.iter(d) do
		assert(d[di] == t[di])
		t[di] = nil
	end
end

function Testbench:TestIterClass()
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

function Testbench:TestNone()
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

function Testbench:TestIterEx()
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

function Testbench:TestEnumerate()
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

function Testbench:TestCallback()
	local cb_called = false
	local lua_cb = function() cb_called = true end
	local python_cb = python.wrap(lua_cb)

	assert(not cb_called)
	python_cb()
	assert(cb_called)
end

function Testbench:TestRoundtrip()
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

function Testbench:TestMultipleReturnValues()
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

function Testbench:TestNumberFromLuaToPython()
	local eqtype = python.eval('lambda a, b: type(a) is type(eval(b))')
	local eqvalue = python.eval('lambda a, b: a == eval(b)')
	local isnan = python.eval('math.isnan')

	local isint = python.eval('lambda n: type(n) is int')
	local isfloat = python.eval('lambda n: type(n) is float')

	local roundtrip = function(num)
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

function Testbench:TestNumberFromPythonToLua()
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

	-- 10^500 >> 2^63 - 1 (signed 64-bit integer maximum value)
	-- 10^500 >> 1.8*10^308 (double-precision floating-point format maximum value)
	assert(not pcall(python.eval, '10**500'),
		"Converting too large Python integers should throw an error")
	
	-- -10^500 << 2^64 (signed 64-bit integer minimum value)
	-- -10^500 << -1.8*10^308 (double-precision floating-point format minimum value)
	assert(not pcall(python.eval, '-10**500'),
		"Converting too large Python integers should throw an error")
end

return Testbench
