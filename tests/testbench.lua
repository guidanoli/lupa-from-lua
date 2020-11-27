-----------------------------------------------------------
-- Tests the lupafromlua Lua C
-- Run from the project root directory
-----------------------------------------------------------

local framework = require "tests.framework"
local python = require "tests.lupa"

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

-----------------------------------------------------------
-- Test cases
-----------------------------------------------------------

Testbench = {
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
	local l = python.builtins.list()
	
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
	local l = python.builtins.list()

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
	python.exec("def " .. funcname .. "(" .. paramname .. "): global " .. varname .. "; " .. varname .. " = " .. paramname)
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

-----------------------------------------------------------
-- Test running
-----------------------------------------------------------

local report = framework:RunTestbench(Testbench)

os.exit(report.failed)