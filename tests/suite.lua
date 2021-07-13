------------------------------------------------------------------------------
-- Test suite
------------------------------------------------------------------------------

local Suite = {}

function Suite:new(o)
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

Suite.assertTrue = Suite:makeAssert{
	assertion = function(self, o) return o end,
	message = function(self, o, extra, ...)
		local msg = tostring(o)
		return self:makeErrorMessage(msg, extra, ...)
	end,
}

Suite.assertFalse = Suite:makeAssert{
	assertion = function(self, o) return not o end,
	message = function(self, o, extra, ...)
		local msg = 'not ' .. tostring(o)
		return self:makeErrorMessage(msg, extra, ...)
	end,
}

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

Suite.assertType = Suite:makeAssert{
	assertion = function(self, o, otype)
		return type(o) == otype
	end,
	message = function(self, o, otype, extra, ...)
		local msg = string.format("type(%s) <%s> == %s",
				tostring(o), type(o), tostring(otype))
		return self:makeErrorMessage(msg, extra, ...)
	end,
}

Suite.assertSubstring = Suite:makeAssert{
	assertion = function(self, haystack, needle)
		return type(haystack) == 'string' and
				type(needle) == 'string' and
				string.find(haystack, needle)
	end,
	message = function(self, haystack, needle, extra, ...)
		local msg = string.format("'%s' contains substring '%s'",
				tostring(haystack), tostring(needle))
		return self:makeErrorMessage(msg, extra, ...)
	end,
}

Suite.assertEqualTypes = Suite:makeAssert{
	assertion = function(self, a, b)
		return type(a) == type(b)
	end,
	message = function(self, a, b, extra, ...)
		local msg = string.format("type(%s) <%s> == type(%s) <%s>",
				tostring(a), type(a), tostring(b), type(b))
		return self:makeErrorMessage(msg, extra, ...)
	end,
}

if math.type == nil then
	Suite.assertEqualNumericTypes = function() end -- no op
else
	Suite.assertEqualNumericTypes = Suite:makeAssert{
		assertion = function(self, a, b)
			return math.type(a) == math.type(b)
		end,
		message = function(self, a, b, extra, ...)
			local msg = string.format("math.type(%s) <%s> == math.type(%s) <%s>",
					tostring(a), math.type(a), tostring(b), math.type(b))
			return self:makeErrorMessage(msg, extra, ...)
		end,
	}
end

----------------------------------------
-- Derived assertions
----------------------------------------

function Suite:assertNil(o, ...)
	self:assertEqual(o, nil, ...)
end

function Suite:assertNotNil(o, ...)
	self:assertNotEqual(o, nil, ...)
end

function Suite:assertNan(o, ...)
	self:assertType(o, "number")
	self:assertNotEqual(o, o, ...)
end

function Suite:assertEqualNumbers(a, b, ...)
	self:assertType(a, "number", ...)
	self:assertType(b, "number", ...)
	self:assertEqualNumericTypes(a, b, ...)
end

----------------------------------------
-- More complex assertions
----------------------------------------

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
	self:assertType(substr, "string")
	local err = self:assertRaises(f, ...)
	self:assertType(err, "string")
	self:assertSubstring(err, substr)
	return err
end

return Suite
