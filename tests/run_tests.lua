-- Simple test runner for Plenary-based tests
local function run_tests()
  -- Ensure plenary is loaded
  local ok, plenary_busted = pcall(require, "plenary.busted")
  if not ok then
    print("ERROR: Could not load plenary.busted")
    vim.cmd("qa!")
    return
  end

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
  local failures = 0
  for _, file in ipairs(test_files) do
    print("\nRunning tests in: " .. vim.fn.fnamemodify(file, ":t"))
    local status, err = pcall(dofile, file)
    if not status then
      print("Error running tests: " .. err)
      failures = failures + 1
    end
  end

  -- Report results
  if failures > 0 then
    print("\n" .. failures .. " test files failed!")
    vim.cmd("cq") -- Exit with error code
  else
    print("\nAll test files passed!")
    vim.cmd("qa!") -- Exit with success
  end
end

run_tests()
