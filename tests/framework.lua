---------------------------------
-- Unit testing framework
---------------------------------

local Framework = {}

-- Run all test cases of a test bench, printing a report at the end
-- Arguments:
-- tb = {
--   name = (testbench name) [string],
--   Test.* = (test case function) [function],
-- }
-- Returns:
-- * {
--   total = (total test cases count) [number],
--   passed = (passed test cases count) [number],
--   failed = (failed test cases count) [number],
-- }
function Framework:RunTestbench(tb)
    print("[ TEST ] Running " .. tb.name .. " tests...")
    print()

    local passed = 0
    local failed = 0

    for testname, testfunc in pairs(tb) do
        if testname:find("^Test") ~= nil then
            local ok, errmsg = pcall(testfunc, tb)
            if ok then
                print("[ PASS ] " .. testname)
                passed = passed + 1
            else
                print("[ FAIL ] " .. testname)
                print(errmsg)
                failed = failed + 1
            end
        end
    end

    print()
    print("[ TEST ] " .. (failed + passed) .. " tests run")
    if failed > 0 then
        print("[ TEST ] " .. failed .. " failed")
    else
        print("[ TEST ] All passed")
    end

    return {
        total = failed + passed,
        failed = failed,
        passed = passed
    }
end

return Framework
