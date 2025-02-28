" Basic test script for Laravel Helper
" Doesn't rely on busted, just checks that the plugin loads

echo "Basic test started"

" Check if we can load the plugin
lua << EOF
-- First, ensure we can see all modules
print("Looking for modules...")
print("Package path: " .. package.path)
print("Runtime path: " .. vim.o.runtimepath)

-- Helper function for colored output
local function colored(msg, color)
  local colors = {
    red = "\27[31m",
    green = "\27[32m",
    yellow = "\27[33m",
    blue = "\27[34m",
    reset = "\27[0m"
  }
  return (colors[color] or "") .. msg .. colors.reset
end

print(colored("Attempting to load laravel-helper module...", "blue"))

-- First try to require all modules directly
print(colored("Loading core components separately...", "blue"))
local modules = {
  "laravel-helper",
  "laravel-helper.version",
  "laravel-helper.config",
  "laravel-helper.core",
  "laravel-helper.commands",
  "laravel-helper.health"
}

for _, module_name in ipairs(modules) do
  local ok, mod = pcall(require, module_name)
  if ok then
    print(colored("✓ Successfully loaded " .. module_name, "green"))
    if module_name == "laravel-helper.version" then
      print("  Version info: " .. mod.string())
    end
  else
    print(colored("✗ Failed to load " .. module_name, "red"))
    print("  Error: " .. tostring(mod))
  end
end

-- Now load the main module
print(colored("\nLoading main module...", "blue"))
local ok, laravel_helper = pcall(require, 'laravel-helper')
if not ok then
  print(colored("✗ Failed to load laravel-helper: " .. tostring(laravel_helper), "red"))
  print("Exiting with error...")
  vim.cmd('cq')  -- Exit with error code
end

print(colored("✓ Main module loaded successfully", "green"))

-- Initialize the module
print(colored("\nInitializing module with setup()...", "blue"))
laravel_helper.setup()

-- Check key components
print(colored("\nChecking key components:", "blue"))

local checks = {
  { 
    name = "setup function", 
    expr = type(laravel_helper.setup) == "function"
  },
  { 
    name = "version", 
    expr = type(laravel_helper.version) == "table" and 
           type(laravel_helper.version.string) == "function"
  },
  { 
    name = "config", 
    expr = type(laravel_helper.config) == "table"
  }
}

local all_pass = true
for _, check in ipairs(checks) do
  if check.expr then
    print(colored("✓ " .. check.name, "green"))
  else
    print(colored("✗ " .. check.name, "red"))
    all_pass = false
  end
end

-- Print all available functions for reference
print(colored("\nAvailable API:", "blue"))
for k, v in pairs(laravel_helper) do
  print("  - " .. k .. " (" .. type(v) .. ")")
  -- If it's a nested table, show its contents too
  if type(v) == "table" and k ~= "core" then
    for subk, subv in pairs(v) do
      print("    ." .. subk .. " (" .. type(subv) .. ")")
    end
  end
end

print(colored("\nBasic test " .. (all_pass and "PASSED" or "FAILED"), all_pass and "green" or "red"))

if not all_pass then
  print("Exiting with error code")
  vim.cmd('cq')
end
EOF

echo "Basic test completed"