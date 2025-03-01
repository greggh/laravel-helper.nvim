-- config_validation_spec.lua
-- Tests for configuration validation in Laravel Helper

describe("config validation", function()
  local config_module

  before_each(function()
    -- Mock vim.validate function
    _G.vim = _G.vim or {}
    _G.vim.validate = function() end
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

    -- Load the config module
    package.loaded["laravel-helper.config"] = nil
    config_module = require("laravel-helper.config")
  end)

  describe("keymaps validation", function()
    it("should validate keymaps.window_navigation must be a boolean", function()
      local config = vim.deepcopy(config_module.defaults)
      config.keymaps.window_navigation = "not-a-boolean"

      local is_valid, error_message = config_module.validate(config)

      assert.is_false(is_valid)
      assert.is_not_nil(error_message)
      assert.equals("keymaps.window_navigation must be a boolean", error_message)
    end)

    it("should accept a true value for keymaps.window_navigation", function()
      local config = vim.deepcopy(config_module.defaults)
      config.keymaps.window_navigation = true

      local is_valid, error_message = config_module.validate(config)

      assert.is_true(is_valid)
      assert.is_nil(error_message)
    end)

    it("should accept a false value for keymaps.window_navigation", function()
      local config = vim.deepcopy(config_module.defaults)
      config.keymaps.window_navigation = false

      local is_valid, error_message = config_module.validate(config)

      assert.is_true(is_valid)
      assert.is_nil(error_message)
    end)
  end)
end)
