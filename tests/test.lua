-- Tests lupafromlua
-- Run from root directory
-- $ lua tests/test.lua

package.cpath = package.cpath .. ";./lib/?.so"

local python = assert(require("lupafromlua"))

Testbench = {}

function Testbench:LuaVersion()
	local lua = python.eval("lua")
	local lupa_lua_version = lua.lua_version
	-- Index Python tuple (0-based)
	local lupa_lua_major = lupa_lua_version[0]
	local lupa_lua_minor = lupa_lua_version[1]
	local semvernums = {}
	for semvernum in string.gmatch(_VERSION, "%d+") do
		table.insert(semvernums, tonumber(semvernum))
	end
	assert(#semvernums >= 2)
	assert(semvernums[1] == lupa_lua_major)
	assert(semvernums[2] == lupa_lua_minor)
end

print("Running tests...")
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
print("Failed:" .. failed)
print("Passed:" .. passed)
print("Total:" .. (failed + passed))

os.exit(failed)
