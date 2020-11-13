-- Tests lupafromlua
-- Run from root directory
-- $ lua tests/test.lua

package.cpath = package.cpath .. ";./lib/?.so"

print(require('lupafromlua'))
