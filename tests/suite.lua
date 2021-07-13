------------------------------------------------------------------------------
-- Test suite
------------------------------------------------------------------------------

local Suite = {}

function Suite:new (o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	return o
end

----------------------------------------
-- Core assertion factories
----------------------------------------

-- Make an function that validates 'assertion' (a function)
-- If assertion fails, raises an error object returned by
-- 'message' (a function), called with all arguments
function Suite:makeAssert(t)
	return function(...)
		if not t.assertion(...) then
			error(t.message(...))
		end
	end
end

-- Make error message from original assertion message
-- and extra arguments. If extra is a function, it calls
-- the function with the remaining arguments. If extra
-- is a string, it concatenates the message with it.
function Suite:makeErrorMessage(msg, extra, ...)
	local fmt = "assertion ``%s`` failed"
	if extra == nil then
		return string.format(fmt, msg)
	else
		fmt = fmt .. " (%s)"
		if type(extra) == 'function' then
			extra = extra(...)
		end
		return string.format(fmt, msg, tostring(extra))
	end
end

----------------------------------------
-- Python unary operation assertions
----------------------------------------

-- Make a function that validates the unary operator
-- 'op' (a format string, where %s is the operand)
-- Optional: msgop for message only
function Suite:makeUnOpAssert(op, msgop)
	msgop = msgop or op -- optional
	local chunk = [[local t = {...}
	local self = t[1]
	return %s]]
	local fmtop = string.format(op, "t[2]")
	return self:makeAssert{
		assertion = assert(load(string.format(chunk, fmtop))),
		message = function(self, a, extra, ...)
			local msg = string.format(msgop, tostring(a))
			return self:makeErrorMessage(msg, extra, ...)
		end,
	}
end

Suite.assertTrue = Suite:makeUnOpAssert("%s", "%s is true")
Suite.assertFalse = Suite:makeUnOpAssert("not %s", "%s is false")
Suite.assertNil = Suite:makeUnOpAssert "%s == nil"
Suite.assertNotNil = Suite:makeUnOpAssert "%s ~= nil"

----------------------------------------
-- Python binary operation assertions
----------------------------------------

-- Make a function that validates the binary
-- operator 'op' (a string)
-- Optional: msgop for message only
function Suite:makeBinOpAssert(op, msgop)
	msgop = msgop or op -- optional
	local chunk = [[local t = {...}
	local self = t[1]
	return %s]]
	local fmtop = string.format(op, "t[2]", "t[3]")
	return self:makeAssert{
		assertion = assert(load(string.format(chunk, fmtop))),
		message = function(self, a, b, extra, ...)
			local msg = string.format(msgop, tostring(a), tostring(b))
			return self:makeErrorMessage(msg, extra, ...)
		end,
	}
end

Suite.assertEqual = Suite:makeBinOpAssert '%s == %s'
Suite.assertNotEqual = Suite:makeBinOpAssert '%s ~= %s'
Suite.assertGreaterThan = Suite:makeBinOpAssert '%s > %s'
Suite.assertGreaterEqual = Suite:makeBinOpAssert '%s >= %s'
Suite.assertLessThan = Suite:makeBinOpAssert '%s < %s'
Suite.assertLessEqual = Suite:makeBinOpAssert '%s <= %s'
Suite.assertType = Suite:makeBinOpAssert('type(%s) == %s', "%s is of type %s")
Suite.assertStringFind = Suite:makeBinOpAssert('string.find(%s, %s)', "string '%s' contains substring '%s'")

-- Calls f(...) and expect error
-- Returns error object
function Suite:assertRaises(f, ...)
	local ok, err = pcall(f, ...)
	self:assertFalse(ok, f, "expected %s to raise error", tostring(f))
	return err
end

-- Calls f(...) and expect string
-- Asserts 'substr' is contained in it
-- Returns error object
function Suite:assertRaisesRegex(substr, f, ...)
	local err = self:assertRaises(f, ...)
	self:assertType(err, "string")
	self:assertStringFind(err, substr)
	return err
end

return Suite
