-- Tests lupafromlua
-- Run from root directory
-- $ lua tests/test.lua

package.cpath = package.cpath .. ";./lib/?.so"

local python = assert(require("lupafromlua"))

------------------------------------------------------------------------------
-- Test bench
------------------------------------------------------------------------------

Testbench = {}

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

------------------------------------------------------------------------------
-- Test framework
------------------------------------------------------------------------------

print("Running lupafromlua tests...")
print()

local passed = 0
local failed = 0

for testcase, testfunc in pairs(Testbench) do
	local ok, errmsg = pcall(testfunc, Testbench)
	if ok then
		print(testcase, "Passed")
		passed = passed + 1
	else
		print(testcase, "Failed", errmsg)
		failed = failed + 1
	end
end

print()
print((failed + passed) .. " tests run")
if failed > 0 then
	print(failed .. " failed")
else
	print("All passed")
end

os.exit(failed)
