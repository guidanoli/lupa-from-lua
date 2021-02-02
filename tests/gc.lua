-----------------------------------------------------------
-- Tests the Lupa garbage collection algorithm
-- Run from the project root directory
-----------------------------------------------------------

local python = require 'lupafromlua'

collectgarbage()
print("Collected garbage")

local l = python.builtins.list()
print("Created Python list l and reference to it in Lua")

collectgarbage()
print("Collected garbage")

l = nil
print("Removed reference to Python list l from Lua")

collectgarbage()
print("Collected garbage")
