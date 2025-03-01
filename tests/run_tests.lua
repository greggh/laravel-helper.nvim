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

  -- Run the tests
  plenary_busted.run(spec_dir)

  -- Exit when done
  vim.cmd("qa!")
end

run_tests()
