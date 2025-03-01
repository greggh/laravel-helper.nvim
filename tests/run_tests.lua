-- Test runner for Plenary-based tests
local ok, plenary = pcall(require, "plenary")
if not ok then
  print("ERROR: Could not load plenary")
  vim.cmd("qa!")
  return
end

-- Setup global test state
_G.TEST_RESULTS = {
  failures = 0,
  successes = 0,
  errors = 0,
}

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
    local success, result = pcall(fn)
    if not success then
      _G.TEST_RESULTS.errors = _G.TEST_RESULTS.errors + 1
      print("  ✗ Error: " .. result)
    end
  end)
end

-- Create our own assert handler to track failures
local luassert = require("luassert")
local old_assert = luassert.assert
luassert.assert = function(...)
  local success, result = pcall(old_assert, ...)
  if not success then
    _G.TEST_RESULTS.failures = _G.TEST_RESULTS.failures + 1
    print("  ✗ Assertion failed: " .. result)
    return success
  else
    _G.TEST_RESULTS.successes = _G.TEST_RESULTS.successes + 1
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
  print("=====================")

  if _G.TEST_RESULTS.failures > 0 or _G.TEST_RESULTS.errors > 0 then
    print("\nSome tests failed!")
    vim.cmd("cq") -- Exit with error code
  else
    print("\nAll tests passed!")
    vim.cmd("qa!") -- Exit with success
  end
end

run_tests()
