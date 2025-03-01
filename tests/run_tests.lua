-- Test runner for Plenary-based tests
local ok, plenary = pcall(require, "plenary")
if not ok then
  print("ERROR: Could not load plenary")
  vim.cmd("qa!")
  return
end

-- Make sure we can load luassert
local ok_assert, luassert = pcall(require, "luassert")
if not ok_assert then
  print("ERROR: Could not load luassert")
  vim.cmd("qa!")
  return
end

-- Setup global test state
_G.TEST_RESULTS = {
  failures = 0,
  successes = 0,
  errors = 0,
  last_error = nil,
}

-- Silence vim.notify during tests to prevent output pollution
local original_notify = vim.notify
vim.notify = function(msg, level, opts)
  -- Capture the message for debugging but don't display it
  if level == vim.log.levels.ERROR then
    _G.TEST_RESULTS.last_error = msg
  end
  -- Return silently to avoid polluting test output
  return nil
end

-- Hook into plenary's test reporter
local busted = require("plenary.busted")
local old_describe = busted.describe
busted.describe = function(name, fn)
  return old_describe(name, function()
    -- Run the original describe block
    fn()
  end)
end

local old_it = busted.it
busted.it = function(name, fn)
  return old_it(name, function()
    -- Create a tracking variable for this specific test
    local test_failed = false

    -- Override assert temporarily to track failures in this test
    local old_local_assert = luassert.assert
    luassert.assert = function(...)
      local success, result = pcall(old_local_assert, ...)
      if not success then
        test_failed = true
        _G.TEST_RESULTS.failures = _G.TEST_RESULTS.failures + 1
        print("  ✗ Assertion failed: " .. result)
        error(result) -- Propagate the error to fail the test
      else
        _G.TEST_RESULTS.successes = _G.TEST_RESULTS.successes + 1
      end
      return result
    end

    -- Run the test
    local success, result = pcall(fn)

    -- Restore the normal assert
    luassert.assert = old_local_assert

    -- If the test failed with a non-assertion error
    if not success and not test_failed then
      _G.TEST_RESULTS.errors = _G.TEST_RESULTS.errors + 1
      print("  ✗ Error: " .. result)
    end
  end)
end

-- Create our own assert handler to track global assertions
local old_assert = luassert.assert
luassert.assert = function(...)
  local success, result = pcall(old_assert, ...)
  if not success then
    _G.TEST_RESULTS.failures = _G.TEST_RESULTS.failures + 1
    print("  ✗ Assertion failed: " .. result)
    return success
  else
    -- No need to increment successes here as we do it in per-test assertions
    return result
  end
end

-- Run the tests
local function run_tests()
  -- Get the root directory of the plugin
  local root_dir = vim.fn.getcwd()
  local spec_dir = root_dir .. "/tests/spec/"

  print("Running tests from directory: " .. spec_dir)

  -- Find all test files
  local test_files = vim.fn.glob(spec_dir .. "*_spec.lua", false, true)
  if #test_files == 0 then
    print("No test files found in " .. spec_dir)
    vim.cmd("qa!")
    return
  end

  print("Found " .. #test_files .. " test files:")
  for _, file in ipairs(test_files) do
    print("  - " .. vim.fn.fnamemodify(file, ":t"))
  end

  -- Run each test file individually
  for _, file in ipairs(test_files) do
    print("\nRunning tests in: " .. vim.fn.fnamemodify(file, ":t"))
    local status, err = pcall(dofile, file)
    if not status then
      print("Error loading test file: " .. err)
      _G.TEST_RESULTS.errors = _G.TEST_RESULTS.errors + 1
    end
  end

  -- Report results
  print("\n==== Test Results ====")
  print("Successes: " .. _G.TEST_RESULTS.successes)
  print("Failures: " .. _G.TEST_RESULTS.failures)
  print("Errors: " .. _G.TEST_RESULTS.errors)
  if _G.TEST_RESULTS.last_error then
    print("Last Error: " .. _G.TEST_RESULTS.last_error)
  end
  print("=====================")

  -- Restore original notify function
  vim.notify = original_notify

  if _G.TEST_RESULTS.failures > 0 or _G.TEST_RESULTS.errors > 0 then
    print("\nSome tests failed!")
    vim.cmd("cq") -- Exit with error code
  else
    print("\nAll tests passed!")
    vim.cmd("qa!") -- Exit with success
  end
end

run_tests()
