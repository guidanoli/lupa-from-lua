-----------------------------------------------------------
-- Tests the lupafromlua Lua C
-- Run from the project root directory
-----------------------------------------------------------

local Suite = require "tests.suite"
local utils = require "tests.utils"
local python = require "lupafromlua"

-----------------------------------------------------------
-- Python imports
-----------------------------------------------------------

python.exec "import math"
python.exec "import traceback"

-----------------------------------------------------------
-- Test suite
-----------------------------------------------------------

local main = Suite:new{python = python}

-----------------------------------------------------------
-- Public methods
-----------------------------------------------------------

function main:LuaVersion()
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
	self:assertGreaterEqual(#semvernums, 2)
	self:assertEqual(semvernums[1], lupa_lua_major)
	self:assertEqual(semvernums[2], lupa_lua_minor)
end

function main:AsAttributeGetter_List()
	local l = python.builtins.list()
	local l_attrs = python.as_attrgetter(l)

	-- Since list implements the sequence protocol, lupa
	-- by default assumes item getter protocol in Python
	self:_assertRaisesPyRegex(python.builtins.TypeError,
		"list indices must be integers",
		function() return l.append end)

	-- By using the as_attrgetter, lupa understands that
	-- any indexation is in fact access to an attribute
	l_attrs.append(0)

	-- Check the effect of calling the append function
	self:assertEqual(l_attrs.__len__(), 1)
end

function main:AsAttributeGetter_Dict()
	local d = python.builtins.dict()
	local d_attrs = python.as_attrgetter(d)

	-- Since dict implements the sequence protocol, lupa
	-- by default assumes item getter protocol in Python
	-- We use u? to accomodate Python 2 and 3 string representations
	self:_assertRaisesPyRegex(python.builtins.KeyError,
		"get", function() return d["get"] end)

	-- By using the as_attrgetter, lupa understands that
	-- any indexation is in fact access to an attribute
	self:assertNil(d_attrs.get("key", python.none))

	-- Insert an entry to the dictionary by using the
	-- traditional brackets notation
	d["key"] = "value"
	self:assertEqual(d_attrs.get("key", python.none), "value")

	-- Test another form of indexation, using the dot notation
	d.key1 = "value1"
	self:assertEqual(d_attrs.get("key1", python.none), "value1")
end

function main:AsAttributeGetter_Builtins()
	local builtins = python.builtins
	-- Since builtins is a module, it does not implement the
	-- sequence protocol, which means that by default, lupa
	-- assumes attribute getter protocol in Python
	local l1 = builtins.list
	local l2 = python.as_attrgetter(builtins).list

	-- Which means that l1 should be equal to l2 in Python
	self:_assertPyEqual(l1, l2)
end

function main:AsItemGetter_List()
	local l = python.builtins.list()
	local l_attrs = python.as_attrgetter(l)

	-- Since list implements the sequence protocol, lupa
	-- by default assumes item getter protocol in Python
	-- But the list is empty so it will fail
	self:_assertRaisesPyRegex(python.builtins.IndexError,
		'list index out of range',
		function() return l[0] end)

	-- Populate the list with numbers in order
	for i = 0, 10 do
		l_attrs.append(i)
	end

	-- Using the brackets notation
	for i = 0, 10 do
		-- Check that the items were added
		-- Remember that Python indexation begins with 0
		self:assertEqual(l[i], i)
	end

	-- Using python.as_itemgetter
	local l_items = python.as_itemgetter(l_attrs)
	for i = 0, 10 do
		-- Check that the items were added
		-- Remember that Python indexation begins with 0
		self:assertEqual(l_items[i], i)
	end
end

function main:AsItemGetter_Dict()
	local d = python.builtins.dict()
	local d_attrs = python.as_attrgetter(d)
	local d_items = python.as_itemgetter(d_attrs)

	-- Since dict implements the sequence protocol, lupa
	-- by default assumes item getter protocol in Python
	-- But the dict is empty so it will fail
	-- We use u? to accomodate Python 2 and 3 string representations
	self:_assertRaisesPyRegex(python.builtins.KeyError,
		"key", function() return d.key end)

	-- Populate the dict with numbers in order
	for i = 0, 10 do
		d[i] = i
	end

	-- Using the brackets notation
	for i = 0, 10 do
		-- Check that the items were added
		self:assertEqual(d[i], i)
	end

	-- Using python.as_itemgetter
	for i = 0, 10 do
		-- Check that the items were added
		self:assertEqual(d_items[i], i)
	end
end

function main:AsFunction_Eval()
	local eval_asfunction = python.as_function(python.eval)

	-- Even though eval is already a wrapper (userdata),
	-- it should be possible to wrap it one more time
	self:assertEqual(eval_asfunction("1 + 1"), 2)
end

function main:Eval()
	local testcases = {
		{ "1", 1 },
		{ "1 + 1", 2 },
		{ "2 * 3", 6 },
		{ "10 / 5", 2 },
		{ "2 ** 4", 16 },
		{ "10 % 7", 3 },
		{ "{}", python.builtins.dict() },
		{ "{'a': 1}", python.builtins.dict{a=1} },
		{ "{'a': 1, 'b': 2, 'c': 3}", python.builtins.dict{a=1, b=2, c=3} },
		{ "()", python.tuple() },
		{ "(1, )", python.tuple(1) },
		{ "(1, 2, 3)", python.tuple(1, 2, 3) },
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
		{ "sorted([1, -5, 3, -1])", python.builtins.list(python.tuple(-5, -1, 1, 3)) },
		{ "sum([1, -5, 3, -1])", -2 },
		{ "None", python.none },
		{ "None", nil },
		{ "False", false },
		{ "True", true },
		{ "(lambda x: x*2)(10)", 20 },
		{ "(lambda x: x*2)([1, 2, 3])", python.builtins.list(python.tuple(1, 2, 3, 1, 2, 3)) },
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
		self:_assertPyEqual(output, ret, 'test #' .. testindex)
	end
end

function main:EvalWithDictionary()
	local noscope = python.builtins.dict{} -- empty scope
	local expression = 'a*b+c'

	self:_assertRaisesPyRegex(python.builtins.TypeError,
		'eval must be given globals and locals when called without a frame',
		python.eval, expression, python.args{locals=noscope})

	-- Without scope, 'a', 'b' and 'c' don't exist, so NameError should be raised
	local test_name_error = function(t)
		self:_assertRaisesPyRegex(python.builtins.NameError,
			"name '[abc]' is not defined",
			python.eval, expression, python.args(t))
	end

	test_name_error{noscope}
	test_name_error{noscope, noscope}
	test_name_error{globals=noscope}
	test_name_error{locals=noscope, globals=noscope}

	local scope = python.builtins.dict{a=2, b=3, c=5} -- scope with names
	local expected_value = 11

	-- With these names in the scope, the expression can be evaluated
	local test_ok = function(t)
		local value = python.eval(expression, python.args(t))
		self:assertEqual(value, expected_value)
	end

	test_ok{scope}
	test_ok{scope, noscope}
	test_ok{noscope, scope}
	test_ok{scope, scope}
	test_ok{locals=noscope, globals=scope}
	test_ok{locals=scope, globals=noscope}
	test_ok{locals=scope, globals=scope}
end

function main:ExecWithDictionary()
	local noscope = python.builtins.dict{}
	local statement = 'd=a*b+c'

	-- Without scope, 'a', 'b' and 'c' don't exist, so NameError should be raised
	local test_name_error = function(t)
		self:_assertRaisesPyRegex(python.builtins.NameError,
			"name '[abc]' is not defined",
			python.exec, statement, python.args(t))
	end

	test_name_error{noscope}
	test_name_error{noscope, noscope}
	test_name_error{locals=noscope}
	test_name_error{globals=noscope}
	test_name_error{locals=noscope, globals=noscope}

	local scope = python.builtins.dict{a=2, b=3, c=5} -- scope with names
	local checkcode = 'd==11'

	-- With these names in the scope, the statement can be executed
	local test_ok = function(t)
		python.exec(statement, python.args(t))
		local checkval = python.eval(checkcode, python.args(t))
		self:assertTrue(checkval)
		scope = python.builtins.dict{a=2, b=3, c=5} -- clear scope
	end

	test_ok{scope}
	test_ok{scope, noscope}
	test_ok{noscope, scope}
	test_ok{scope, scope}
	test_ok{locals=noscope, globals=scope}
	test_ok{locals=scope, globals=noscope}
	test_ok{locals=scope, globals=scope}
end

function main:ExecAssignment()
	local varname = self:_newname()
	local value = math.random(128)

	python.exec(varname .. " = " .. value)

	self:assertEqual(python.eval(varname), value)
end

function main:ExecCall()
	local funcname = self:_newname()
	local varname = self:_newname()
	local paramname = self:_newname()
	local value = math.random(128)

	python.exec(varname .. " = None")
	python.exec("def " .. funcname .. "(" .. paramname .. "):\n" ..
		"\tglobal " .. varname .. "\n" ..
		"\t" .. varname .. " = " .. paramname)
	python.exec(funcname .. "(" .. value .. ")")

	self:assertEqual(python.eval(varname), value)
end

function main:ExecAssert()
	python.exec("assert True")
	self:_assertRaisesPyExc(python.builtins.AssertionError, python.exec, "assert False")
end

function main:ExecPass()
	python.exec("pass")
end

function main:ExecAugmentedAssignment()
	local varname = self:_newname()

	python.exec(varname .. " = 321")
	python.exec(varname .. " += 123")
	self:assertEqual(python.eval(varname), 444)
end

function main:ExecDel()
	local varname = self:_newname()

	python.exec(varname .. " = { 1:1 }")
	self:_assertPyEqual(python.eval(varname), python.builtins.dict{1})
	python.exec("del " .. varname .. "[1]")
	self:_assertPyEqual(python.eval(varname), python.builtins.dict())
end

function main:ExecReturn()
	self:_assertRaisesPyExc(python.builtins.SyntaxError, python.exec, "return")
end

function main:ExecYield()
	self:_assertRaisesPyExc(python.builtins.SyntaxError, python.exec, "yield")
end

function main:ExecRaise()
	self:_assertRaisesPyExc(python.builtins.RuntimeError, python.exec, "raise RuntimeError")
end

function main:ExecBreak()
	self:_assertRaisesPyExc(python.builtins.SyntaxError, python.exec, "break")
end

function main:ExecContinue()
	self:_assertRaisesPyExc(python.builtins.SyntaxError, python.exec, "continue")
end

function main:ExecImport()
	python.exec("from math import sqrt")
	local sqrt2 = python.eval("sqrt(2)")
	self:assertEqual(sqrt2, math.sqrt(2))
end

function main:ExecGlobal()
	local varname = self:_newname()

	python.exec("global " .. varname)
end

function main:ExecNonLocal()
	local varname = self:_newname()
	self:_assertRaisesPyExc(python.builtins.SyntaxError, python.exec, "nonlocal " .. varname)
end

function main:IterTuple()
	local t = python.tuple(1, 2, 3)
	local i = 1
	for ti in python.iter(t) do
		self:assertEqual(i, ti)
		i = i + 1
	end
end

function main:IterDict()
	local t = {a=1, b=2, c=3}
	local d = python.builtins.dict(t)
	for di in python.iter(d) do
		self:assertTrue(d[di], t[di])
		t[di] = nil
	end
end

function main:IterClass()
	local classname = self:_newname()

	python.exec("class " .. classname .. ":\n" ..
		"\tdef __init__(self, obj):\n" ..
		"\t\tself.obj = obj\n" ..
		"\tdef __iter__(self):\n" ..
		"\t\treturn iter(self.obj)")

	local t = python.tuple(1, 2, 3)
	local instance = python.eval(classname)(t)

	local i = 1
	for ci in python.iter(instance) do
		self:assertEqual(ci, i)
		i = i + 1
	end
end

function main:None()
	self:_assertPyEqual(python.none, nil)
	self:assertNotNil(python.none)
	self:assertTrue(python.none)
	self:assertEqual(tostring(python.none), "None")
	self:assertEqual(python.builtins.str(python.none), "None")
	self:assertEqual(python.builtins.str(nil), "None")

	local d = python.builtins.dict{[python.none]=python.none}

	local entered = false
	for di in python.iter(d) do
		self:assertEqual(di, python.none)
		entered = true
	end
	assert(entered)

	entered = false
	for k, v in python.iterex(python.as_attrgetter(d).items()) do
		self:assertEqual(k, python.none)
		self:assertEqual(v, nil)
		entered = true
	end
	assert(entered)

	local t = python.tuple(nil, nil)
	entered = false
	for ti in python.iter(t) do
		self:assertEqual(ti, python.none)
		entered = true
	end
	assert(entered)
end

function main:IterEx()
	local t = {a=1, b=2, c=3}
	local d = python.builtins.dict(t)
	local d_items = python.as_attrgetter(d).items()

	for key, value in python.iterex(d_items) do
		self:assertEqual(t[key], value)
		t[key] = nil
	end

	local generatorname = self:_newname()
	python.exec("def " .. generatorname .. "(n):\n" ..
		"\tfor i in range(n):\n" ..
		"\t\tyield i, -i, 2*i, i*i")

	local n = 10
	local g = python.eval(generatorname .. "(" .. n .. ")")

	i = 0
	for a, b, c, d in python.iterex(g) do
		self:assertEqual(a, i)
		self:assertEqual(b, -i)
		self:assertEqual(c, 2*i)
		self:assertEqual(d, i*i)
		i = i + 1
	end
end

function main:Enumerate()
	local l, entered

	t = python.tuple(0, 1, 2, 3)
	entered = false
	for i, ti in python.enumerate(t) do
		self:assertEqual(i, ti)
		entered = true
	end
	assert(entered)

	t = python.tuple()
	entered = false
	for i, ti in python.enumerate(t) do
		entered = true
	end
	assert(not entered)
end

function main:CallPyFunction()
	local returnall = python.eval("lambda *args: args")
	local t = {}
	for i = 1, 1000 do
		t[i] = i
	end
	local ret = returnall(table.unpack(t))
	self:assertEqual(python.builtins.len(ret), 1000)
	for i = 1, 1000 do
		self:assertEqual(ret[i-1], i)
	end
end

function main:Callback()
	local cb_called = false
	local function lua_cb() cb_called = true end
	local python_cb = self:_makeLambda(lua_cb)

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
	self:assertEqual(python.builtins.len(ret), 1000)
	for i = 1, 1000 do
		self:assertEqual(ret[i-1], i)
	end
end

function main:Roundtrip()
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
		local python_cb = self:_makeLambda(function() return testcase end)
		local ok, ret = pcall(python_cb)
		if not ok then
			error("failed test #" .. testindex .. ": " .. tostring(ret))
		end
		if ret ~= testcase then
			error("failed test #" .. testindex .. ": obtained " .. tostring(ret))
		end
	end
end

function main:MultipleReturnValues()
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

	local identity = self:_makeLambda(function(...) return ... end)

	for testindex, testcase in ipairs(testcases) do
		local ok, ret = pcall(identity, table.unpack(testcase.input))
		if not ok then
			error("failed test #" .. testindex .. ": " .. tostring(ret))
		end
		self:_assertPyEqual(ret, testcase.output, 'test #' .. testindex)
	end
	
end

function main:NumberFromLuaToPython()
	local eqvalue = python.eval('lambda a, b: a == eval(b)')
	local eqvalueself = function(o) return eqvalue(o, tostring(o)) end
	local isnan = python.eval('math.isnan')
	local isinteger = function(o) return self:_isinstance(o, 'int', 'long') end
	local isfloat = function(o) return self:_isinstance(o, 'float') end

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

	if math.tointeger ~= nil then
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

function main:NumberFromPythonToLua()
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
	self:_assertPyOverflow('10**500')

	-- -10^500 << -2^63 (signed 64-bit integer minimum value)
	-- -10^500 << -1.8*10^308 (double-precision floating-point format minimum value)
	self:_assertPyOverflow('-10**500')
end

function main:NoHandler()
	python.set_overflow_handler(nil)
	local proxy = python.eval('10**500')
	local proxytype = python.builtins.type(proxy)
	assert(proxytype == python.builtins.int or
	       proxytype == python.builtins.long)
	local proxystr = python.builtins.str(proxy)
	local expectedstr = '1' .. string.rep('0', 500)
	self:assertEqual(proxystr, expectedstr)
end

function main:EmptyHandler()
	python.set_overflow_handler(function() end)
	self:assertNil(python.eval('10**500'))
end

function main:HandlerWithLuaError()
	python.set_overflow_handler(function() error() end)
	self:_assertPyOverflow('2**64')
	self:_assertPyOverflow('10**500')
end

function main:FloatFallbackHandler()
	python.set_overflow_handler(python.builtins.float)
	self:assertEqual(python.eval('2**64'), 2^64)
	self:_assertPyOverflow('10**500')
end

function main:GarbageCollector()
	-- Test garbage collection, by making sure that the
	-- amount of memory used by Lua before and after calling f
	-- stays the same (that is, all garbage is collected)
	local function testgc(f)
		local before, after, diff
		local ntests = 10
		local ncycles = 20
		for _ = 1, ntests do
			for _ = 1, ncycles do collectgarbage() end
			before = collectgarbage('count')
			f()
			for _ = 1, ncycles do collectgarbage() end
			after = collectgarbage('count')
			diff = after - before
			if diff == 0 then
				return
			end
		end
		error(string.format("%d bytes leaked", diff*1024))
	end

	testgc(function() end)	
	testgc(function() python.tuple() end)
	testgc(function() local t = python.tuple() end)
	testgc(function() python.eval('lua.eval("{}")') end)
	testgc(function() local t = { python.tuple() } end)
	testgc(function()
		local d = python.builtins.dict()
		d.ref = d
	end)
	testgc(function()
		local t = { dict = python.builtins.dict() }
		t.dict.ref = t
		setmetatable(t, {__mode = "v"})
	end)
end

function main:ExceptionMessage()
	local exc = self:_assertRaisesPyExc(python.builtins.Exception, python.exec, 'raise Exception("xyz")')
	self:assertEqual(tostring(exc), 'xyz')
end

function main:MissingReference()
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
		local err = self:assertRaises(f, t.obj)
		local errmsg = "deleted python object"
		if type(err) == 'string' then
			self:assertStringFind(err, errmsg)
		else
			self:assertType(err, "userdata")
			self:_assertPyType(err.value, python.builtins.ReferenceError)
			local arg = python.as_attrgetter(err.value).args
			self:_assertPyLength(arg, 1)
			self:assertEqual(arg[0], errmsg)
		end
	end

	testmissingref(python.builtins.dict(), function(obj) print(obj) end)                              -- __tostring
	testmissingref(python.builtins.dict(), function(obj) print(obj[1]) end)                           -- __index
	testmissingref(python.builtins.dict(), function(obj) print(python.as_itemgetter(obj)[1]) end)     -- __index (itemgetter)
	testmissingref(python.builtins.dict(), function(obj) print(python.as_attrgetter(obj).items) end)  -- __index (attrgetter)
	testmissingref(python.builtins.dict(), function(obj) obj[1] = 1 end)                              -- __newindex
	testmissingref(python.builtins.dict(), function(obj) python.as_itemgetter(obj)[1] = 1 end)        -- __newindex (itemgetter)
	testmissingref(self:_makeLambda(print), function(obj) python.as_attrgetter(obj).a = 1 end)        -- __newindex (attrgetter)
	testmissingref(self:_makeLambda(print), function(obj) obj() end)                                  -- __call

	testmissingref(python.builtins.dict(), python.builtins.len)   -- call from Python
	testmissingref(python.builtins.dict(), python.iter)           -- iteration
	testmissingref(python.builtins.dict(), python.iterex)         -- iteration (explode tuples)
	testmissingref(python.builtins.dict(), python.enumerate)      -- iteration (with indices)
	testmissingref(python.builtins.dict(), python.as_function)    -- cast to function
	testmissingref(python.builtins.dict(), python.as_itemgetter)  -- item getter protocol
	testmissingref(python.builtins.dict(), python.as_attrgetter)  -- attribute getter protocol
end

function main:LuaTableIterable()
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
		self:assertEqual(dsize, tsize)
		for key, tvalue in pairs(t) do
			dvalue = d[key]
			self:assertEqual(dvalue, tvalue)
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

function main:PythonArguments()
	-- Identity function
	local identity = python.eval("lambda *args, **kwargs: (args, kwargs)")

	-- Tests Python arguments
	-- Calls the identity function with ...
	-- and checks if args and kwargs match
	local function testpyargs(args, kwargs, ...)
		local ret = identity(...)
		local retargs = ret[0]
		local retkwargs = ret[1]
		self:assertEqual(#args, python.builtins.len(retargs))
		for i, arg in ipairs(args) do
			self:assertEqual(retargs[i-1], arg)
		end
		for key, value in pairs(kwargs) do
			self:assertEqual(retkwargs[key], value)
		end
		local items = python.as_attrgetter(retkwargs).items()
		for key, value in python.iterex(items) do
			self:assertEqual(kwargs[key], value)
		end
	end

	self:assertRaisesRegex('table expected, got no value', python.args)
	self:assertRaisesRegex('table expected, got number', python.args, 1)
	self:_assertRaisesPyRegex(python.builtins.IndexError, 'table index out of range', python.args, {[0]=7})
	self:_assertRaisesPyRegex(python.builtins.IndexError, 'table index out of range', python.args, {[2]=7})
	self:_assertRaisesPyRegex(python.builtins.TypeError, 'table key is neither an integer nor a string', python.args, {[true]=7})

	testpyargs({}, {})
	testpyargs({}, {}, python.args{})
	testpyargs({1}, {}, python.args{1})
	testpyargs({1, 2, 3}, {}, python.args{1, 2, 3})
	testpyargs({}, {a=1}, python.args{a=1})
	testpyargs({}, {a=1, b=2, c=3}, python.args{a=1, b=2, c=3})
	testpyargs({1}, {a=1}, python.args{a=1, 1})
	testpyargs({1}, {a=1, b=2, c=3}, python.args{a=1, b=2, c=3, 1})
	testpyargs({1, 2, 3}, {a=1}, python.args{a=1, 1, 2, 3})
	testpyargs({1, 2, 3}, {a=1, b=2, c=3}, python.args{a=1, b=2, c=3, 1, 2, 3})
end

function main:ReloadLibrary()
	local lib1 = python
	package.loaded.lupafromlua = nil
	local lib2 = require "lupafromlua"
	self:assertEqual(lib1, lib2, "not the same library")
end

function main:LuaErrorRoundtrip()
	local foo = function() error('xyz') end
	self:assertRaisesRegex('xyz', self:_makeLambda(foo))
end

function main:ExceptionMessageWithTraceback()
	local err = self:assertRaises(python.eval, "0/0")
	self:assertType(err, "userdata")
	local errmsg = tostring(err)
	self:assertStringFind(errmsg, "Traceback")
	self:assertStringFind(errmsg, "ZeroDivisionError")
end

------------------------------------------------------------------------------
-- Private methods
------------------------------------------------------------------------------

main._assertPyType = main:makeBinOpAssert('self.python.builtins.isinstance(%s, %s)', 'isinstance(%s, %s)')
main._pyequal = python.eval('lambda a, b: a == b')
main._assertPyEqual = main:makeBinOpAssert('self._pyequal(%s, %s)', "%s == %s [in Python]")
main._assertPyLength = main:makeBinOpAssert('self.python.builtins.len(%s) == %s', "len(%s) == %s")

-- Generate unique name for Python variable name
function main:_newname()
	if self._namecnt == nil then
		self._namecnt = 0
	end
	local name = 't' .. self._namecnt
	self._namecnt = self._namecnt + 1
	return name
end

-- Checks if the 'obj' (Python object) is an instance
-- of at least one of the types listed after (strings)
-- If a type doesn't exist, it is simply ignored
function main:_isinstance(obj, ...)
	local builtins = python.builtins
	local isinstance = builtins.isinstance
	local getbuiltin = function(name)
		return builtins[name]
	end
	for _, typename in ipairs{...} do
		local ok, typeobj = pcall(getbuiltin, typename)
		if ok and isinstance(obj, typeobj) then
			return true
		end
	end
	return false
end

-- Call f(...) and expect it to raise a Python exception
-- Asserts exception is of type 'etype'
-- Returns Python exception object (as attribute getter)
function main:_assertRaisesPyExc(etype, f, ...)
	local exc = self:assertRaises(f, ...)
	self:assertType(exc, "userdata")
	self:_assertPyType(exc.value, python.builtins.BaseException)
	self:_assertPyType(exc.value, exc.etype)
	self:assertNotNil(exc.traceback)
	self:_assertPyType(exc.value, etype, tostring, exc)
	return python.as_attrgetter(exc.value)
end

-- Call f(...) and expect it to raise a Python exception
-- Asserts exception is of type 'etype' and contains
-- 'substr' when converted to string
-- Returns the exception message
function main:_assertRaisesPyRegex(etype, substr, f, ...)
	local obj = self:_assertRaisesPyExc(etype, f, ...)
	local errmsg = tostring(obj)
	self:assertStringFind(errmsg, substr)
	return errmsg
end

-- Try evaluating 'number' (a string) and expect an OverflowError
-- to be raised by Python. Returns the exception object
function main:_assertPyOverflow(number)
	return self:_assertRaisesPyExc(python.builtins.OverflowError, python.eval, number)
end

-- Python lambda constructor
function main:_makeLambda(f)
	return python.eval("lambda f: lambda *args: f(*args)")(f)
end

return main
