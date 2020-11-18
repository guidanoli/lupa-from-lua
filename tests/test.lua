-- Tests lupafromlua
-- Run from root directory
-- $ lua tests/test.lua

package.cpath = package.cpath .. ";./lib/?.so"

local python, libpath = require('lupafromlua')

if python then
	print("lupafromlua successfully loaded from "..libpath)
else
	os.exit(1)
end

local builtins = python.as_attrgetter(python.builtins).__dict__

local list = builtins.list()

print()
print("Empty list:")
print(list)

for i = 1, 10 do
	python.as_attrgetter(list).append(i)
end

print()
print("List with numbers from 1 to 10:")
print(list)

local dict = builtins.dict()

print()
print("Empty dictionary:")
print(dict)

for i = 1, 10 do
	dict[i] = i*i
end

print()
print("Dictionary mapping x to x^2 for x from 1 to 10:")
print(dict)
