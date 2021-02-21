-- Usage: lua tests/timeit.lua [<code> [<n>]]
-- Arguments:
--   code - valid lua code
--   n - number of loops
if type(arg) == "table" and arg[0]:find("timeit%.lua$") then
	local utils = require 'tests.utils'
	local load = loadstring or load
	local f = load(arg[1] or '')
	local n = tonumber(arg[2]) or 1000000
	local cb = utils:GetProgressBarCallback(80, io.stderr)
	local avg, stddev = utils:Benchmark(f, n, cb)
	print("Average (s)", avg)
	print("Stddev. (s)", stddev)
end
