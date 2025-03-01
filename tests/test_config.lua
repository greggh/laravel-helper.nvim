-- Simple manual test for config validation

-- Mock vim functions
_G.vim = _G.vim or {}
_G.vim.validate = function()
  return true
end
_G.vim.inspect = function(obj)
  if type(obj) ~= "table" then
    return tostring(obj)
  end
  local result = "{ "
  for k, v in pairs(obj) do
    result = result .. k .. " = " .. _G.vim.inspect(v) .. ", "
  end
  return result .. "}"
end
_G.vim.deepcopy = function(obj)
  if type(obj) ~= "table" then
    return obj
  end
  local res = {}
  for k, v in pairs(obj) do
    res[k] = _G.vim.deepcopy(v)
  end
  return res
end

-- Load the config module directly
package.path = package.path .. ";/home/gregg/Projects/neovim/plugins/laravel-helper/lua/?.lua"
local config = require("laravel-helper.config")

print("Default config:", vim.inspect(config.defaults))

-- Test valid config
local valid_config = vim.deepcopy(config.defaults)
local is_valid, error_message = config.validate(valid_config)
print("\nValid config test:")
print("Is valid:", is_valid)
print("Error message:", error_message or "nil")

-- Test invalid window_navigation (string instead of boolean)
local invalid_config = vim.deepcopy(config.defaults)
invalid_config.keymaps.window_navigation = "not-a-boolean"
local is_valid, error_message = config.validate(invalid_config)
print("\nInvalid window_navigation test:")
print("Is valid:", is_valid)
print("Error message:", error_message or "nil")

-- Test false window_navigation (should be valid)
local false_config = vim.deepcopy(config.defaults)
false_config.keymaps.window_navigation = false
local is_valid, error_message = config.validate(false_config)
print("\nFalse window_navigation test:")
print("Is valid:", is_valid)
print("Error message:", error_message or "nil")
