" Config module test script for Laravel Helper
" Tests the configuration validation and merging

echo "Config test started"

" Check if we can load the plugin
lua << EOF
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

-- Test setup
print(colored("Testing config module...", "blue"))

-- Load the config module
local ok, config = pcall(require, "laravel-helper.config")
if not ok then
  print(colored("✗ Failed to load config module: " .. tostring(config), "red"))
  vim.cmd('cq')  -- Exit with error code
end

print(colored("✓ Config module loaded successfully", "green"))

-- Test default configuration
print(colored("\nTesting default configuration...", "blue"))
local tests = {
  { 
    name = "auto_detect default", 
    expected = true,
    actual = config.defaults.auto_detect
  },
  { 
    name = "docker_timeout default", 
    expected = 360000,
    actual = config.defaults.docker_timeout
  },
  { 
    name = "prefer_sail default", 
    expected = true,
    actual = config.defaults.prefer_sail
  },
  { 
    name = "commands is table",
    expected = "table",
    actual = type(config.defaults.commands)
  },
  { 
    name = "commands contains IDE Helper commands",
    expected = true,
    actual = #config.defaults.commands >= 3
  }
}

local all_pass = true
for _, test in ipairs(tests) do
  if test.actual == test.expected then
    print(colored("✓ " .. test.name, "green"))
  else
    print(colored("✗ " .. test.name .. " - Expected: " .. tostring(test.expected) .. ", Got: " .. tostring(test.actual), "red"))
    all_pass = false
  end
end

-- Test validation
print(colored("\nTesting configuration validation...", "blue"))

local validation_tests = {
  {
    name = "Valid config passes validation",
    config = {
      auto_detect = false,
      docker_timeout = 120000,
      prefer_sail = false,
      commands = {"test1", "test2"}
    },
    should_pass = true
  },
  {
    name = "Invalid type for auto_detect",
    config = {
      auto_detect = "yes",  -- String instead of boolean
      docker_timeout = 120000,
      prefer_sail = false,
      commands = {"test1", "test2"}
    },
    should_pass = false
  },
  {
    name = "Invalid type for docker_timeout",
    config = {
      auto_detect = true,
      docker_timeout = "120000",  -- String instead of number
      prefer_sail = false,
      commands = {"test1", "test2"}
    },
    should_pass = false
  },
  {
    name = "Negative docker_timeout",
    config = {
      auto_detect = true,
      docker_timeout = -1,  -- Negative number
      prefer_sail = false,
      commands = {"test1", "test2"}
    },
    should_pass = false
  },
  {
    name = "Invalid commands (not a table)",
    config = {
      auto_detect = true,
      docker_timeout = 120000,
      prefer_sail = false,
      commands = "test1,test2"  -- String instead of table
    },
    should_pass = false
  },
  {
    name = "Invalid command entry (not a string)",
    config = {
      auto_detect = true,
      docker_timeout = 120000,
      prefer_sail = false,
      commands = {"test1", 123}  -- Number instead of string
    },
    should_pass = false
  }
}

for _, test in ipairs(validation_tests) do
  local is_valid, error_message = config.validate(test.config)
  
  if is_valid == test.should_pass then
    print(colored("✓ " .. test.name, "green"))
    if not is_valid and error_message then
      print("  Error message: " .. error_message)
    end
  else
    print(colored("✗ " .. test.name .. " - Expected validation: " .. tostring(test.should_pass) .. ", Got: " .. tostring(is_valid), "red"))
    if error_message then
      print("  Error message: " .. error_message)
    end
    all_pass = false
  end
end

-- Test configuration merging
print(colored("\nTesting configuration merging...", "blue"))

local merge_tests = {
  {
    name = "Merge empty config",
    user_config = {},
    expected = config.defaults,
    should_pass = true
  },
  {
    name = "Merge with custom auto_detect",
    user_config = { auto_detect = false },
    expected_changes = { auto_detect = false },
    should_pass = true
  },
  {
    name = "Merge with custom commands",
    user_config = { commands = {"custom1", "custom2"} },
    expected_changes = { commands = {"custom1", "custom2"} },
    should_pass = true
  },
  {
    name = "Merge with invalid config",
    user_config = { auto_detect = "yes" },
    should_pass = false
  }
}

for _, test in ipairs(merge_tests) do
  local merged, is_valid, error_message = config.merge(test.user_config)
  
  if is_valid == test.should_pass then
    print(colored("✓ " .. test.name .. " validation", "green"))
    
    -- If we expect specific changes, check them
    if test.expected_changes then
      local changes_match = true
      for k, v in pairs(test.expected_changes) do
        if type(v) == "table" then
          -- For tables like commands, check length and contents
          if #merged[k] ~= #v then
            changes_match = false
            print(colored("✗ " .. test.name .. " - Expected " .. k .. " length: " .. #v .. ", Got: " .. #merged[k], "red"))
          else
            for i = 1, #v do
              if merged[k][i] ~= v[i] then
                changes_match = false
                print(colored("✗ " .. test.name .. " - Expected " .. k .. "[" .. i .. "]: " .. v[i] .. ", Got: " .. merged[k][i], "red"))
              end
            end
          end
        elseif merged[k] ~= v then
          changes_match = false
          print(colored("✗ " .. test.name .. " - Expected " .. k .. ": " .. tostring(v) .. ", Got: " .. tostring(merged[k]), "red"))
        end
      end
      
      if changes_match then
        print(colored("✓ " .. test.name .. " changes applied correctly", "green"))
      else
        all_pass = false
      end
    end
    
    -- If we expect it to match defaults exactly
    if test.expected then
      local matches = true
      for k, v in pairs(test.expected) do
        if type(v) == "table" then
          -- For tables like commands, check length and contents
          if #merged[k] ~= #v then
            matches = false
            print(colored("✗ " .. test.name .. " - Expected " .. k .. " length: " .. #v .. ", Got: " .. #merged[k], "red"))
          else
            for i = 1, #v do
              if merged[k][i] ~= v[i] then
                matches = false
                print(colored("✗ " .. test.name .. " - Expected " .. k .. "[" .. i .. "]: " .. v[i] .. ", Got: " .. merged[k][i], "red"))
              end
            end
          end
        elseif merged[k] ~= v then
          matches = false
          print(colored("✗ " .. test.name .. " - Expected " .. k .. ": " .. tostring(v) .. ", Got: " .. tostring(merged[k]), "red"))
        end
      end
      
      if matches then
        print(colored("✓ " .. test.name .. " matches expected config", "green"))
      else
        all_pass = false
      end
    end
  else
    print(colored("✗ " .. test.name .. " - Expected validation: " .. tostring(test.should_pass) .. ", Got: " .. tostring(is_valid), "red"))
    if error_message then
      print("  Error message: " .. error_message)
    end
    all_pass = false
  end
end

print(colored("\nConfig test " .. (all_pass and "PASSED" or "FAILED"), all_pass and "green" or "red"))

if not all_pass then
  print("Exiting with error code")
  vim.cmd('cq')
end
EOF

echo "Config test completed"