-- window_navigation_spec.lua
-- Tests specifically focused on window_navigation config

describe("window_navigation config", function()
  local config_module

  before_each(function()
    -- Ensure Vim globals exist
    _G.vim = _G.vim or {}
    _G.vim.validate = function() end
    _G.vim.log = _G.vim.log or { levels = { ERROR = 4 } }

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

    -- Reload config module
    package.loaded["laravel-helper.config"] = nil
    config_module = require("laravel-helper.config")
  end)

  it("should correctly validate window_navigation as a boolean", function()
    -- Create a copy of the default config
    local test_config = vim.deepcopy(config_module.defaults)

    -- Set window_navigation to a non-boolean value
    test_config.keymaps.window_navigation = "not-a-boolean"

    -- This should trigger an error in vim.notify
    local is_valid, error_message = config_module.validate(test_config)
    assert.is_false(is_valid)
    assert.equals("keymaps.window_navigation must be a boolean", error_message)
  end)
end)
