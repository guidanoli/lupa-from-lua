-- Tests lupafromlua
-- Run from root directory
-- $ lua tests/test.lua

local Framework = require "tests/framework"

package.cpath = package.cpath .. ";./lib/?.so"

local python = assert(require("lupafromlua"))

Testbench = {
	meta = {
		name = "lupafromlua",
	},
}

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
	local l = python.builtins.list()
	
	assert(not pcall(function()
		-- Since list implements the sequence protocol, lupa
		-- by default assumes item getter protocol in Python
		local append_func_err = l.append
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
	local d = python.builtins.dict()
	
	assert(not pcall(function()
		-- Since dict implements the sequence protocol, lupa
		-- by default assumes item getter protocol in Python
		local get_func_err = d.get
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
	local py_eq = python.eval("lambda x, y: x == y")
	assert(py_eq(l1,l2))
end

function Testbench:AsItemGetter_List()
	local l = python.builtins.list()

	assert(not pcall(function ()
		-- Since list implements the sequence protocol, lupa
		-- by default assumes item getter protocol in Python

		-- But the list is empty so it will fail
		local first_element = l[0]
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
	local d = python.builtins.dict()

	assert(not pcall(function ()
		-- Since dict implements the sequence protocol, lupa
		-- by default assumes item getter protocol in Python

		-- But the dict is empty so it will fail
		local any_element = d["key"]
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

local report = Framework:RunTestbench(Testbench)

os.exit(report.failed)