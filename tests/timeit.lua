local load_cb = function() return io.stdin:read() end
print("Setup code:")
assert(load(load_cb), "setup code is invalid")()
print("Test code:")
local f = assert(load(load_cb), "test code is invalid")
local utils = require 'tests.utils'
local progress_cb = utils:GetProgressBarCallback(80, io.stderr)
print("Progress:")
local mean, stddev = utils:Benchmark(f, 1000000, progress_cb)
print()
print("Mean   ", mean)
print("Std Dev", stddev)
