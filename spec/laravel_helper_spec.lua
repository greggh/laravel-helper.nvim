-- laravel_helper_spec.lua
-- Test specification for Laravel Helper plugin

local mock = require("luassert.mock")

describe("Laravel Helper", function()
  local laravel_helper
  local filereadable_mock
  local lfs_mock
  
  before_each(function()
    -- Mock vim namespace for testing
    _G.vim = _G.vim or {}
    _G.vim.fn = _G.vim.fn or {}
    _G.vim.fn.filereadable = _G.vim.fn.filereadable or function() return 0 end
    _G.vim.fn.getcwd = _G.vim.fn.getcwd or function() return "/test/project" end
    _G.vim.fn.exists = _G.vim.fn.exists or function() return 0 end
    _G.vim.g = _G.vim.g or {}
    _G.vim.notify = _G.vim.notify or function() end
    _G.vim.api = _G.vim.api or {}
    _G.vim.api.nvim_create_autocmd = _G.vim.api.nvim_create_autocmd or function() end
    _G.vim.log = _G.vim.log or {levels = {INFO = 2, WARN = 3, ERROR = 4}}
    _G.vim.tbl_deep_extend = _G.vim.tbl_deep_extend or function(_, tbl1, tbl2)
      local result = vim.deepcopy(tbl1)
      for k, v in pairs(tbl2) do result[k] = v end
      return result
    end
    
    _G.vim.validate = function(tbl)
      for _, v in pairs(tbl) do
        local val, type_name = v[1], v[2]
        if type(val) ~= type_name then
          error(string.format("Expected %s, got %s", type_name, type(val)))
        end
      end
    end
    
    _G.vim.deepcopy = function(obj)
      if type(obj) ~= 'table' then return obj end
      local res = {}
      for k, v in pairs(obj) do res[k] = _G.vim.deepcopy(v) end
      return res
    end
    
    -- Create mocks
    filereadable_mock = mock(_G.vim.fn, "filereadable", true)
    
    -- Reset filereadable mock to return 0 by default
    filereadable_mock.returns(0)
    
    -- Load the plugin after mocks are in place
    package.loaded["laravel-helper"] = nil
    package.loaded["laravel-helper.core"] = nil
    package.loaded["laravel-helper.commands"] = nil
    package.loaded["laravel-helper.health"] = nil
    package.loaded["laravel-helper.version"] = nil
    package.loaded["laravel-helper.config"] = nil
    
    -- Create a basic mock core module
    package.loaded["laravel-helper.core"] = {
      setup = function() end,
      find_laravel_root = function() 
        if filereadable_mock.calls[1] and filereadable_mock.calls[1].vals[1]:match("artisan$") then
          return "/test/project"
        end
        return nil
      end,
      is_laravel_project = function() 
        return filereadable_mock.calls[1] and filereadable_mock.calls[1].vals[1]:match("artisan$") ~= nil
      end,
      setup_auto_ide_helper = function() end
    }
    
    laravel_helper = require("laravel-helper")
  end)
  
  after_each(function()
    mock.revert(filereadable_mock)
  end)
  
  describe("version", function()
    it("has a semantic version", function()
      laravel_helper.setup()
      assert.is_not_nil(laravel_helper.version)
      assert.is_not_nil(laravel_helper.version.major)
      assert.is_not_nil(laravel_helper.version.minor)
      assert.is_not_nil(laravel_helper.version.patch)
      assert.is_function(laravel_helper.version.string)
      
      local version_str = laravel_helper.version.string()
      assert.matches("%d+%.%d+%.%d+", version_str)
    end)
  end)
  
  describe("configuration", function()
    it("merges user config with defaults", function()
      local user_config = { prefer_sail = false }
      laravel_helper.setup(user_config)
      
      assert.is_true(laravel_helper.config.auto_detect)
      assert.is_false(laravel_helper.config.prefer_sail)
    end)
    
    it("validates user config", function()
      local notify_mock = mock(_G.vim, "notify", true)
      local user_config = { prefer_sail = "not_a_boolean" }
      
      laravel_helper.setup(user_config)
      assert.spy(notify_mock).was_called()
      
      mock.revert(notify_mock)
    end)
  end)
  
  describe("laravel project detection", function()
    it("returns true when artisan file is present", function()
      filereadable_mock.on_call_with("/test/project/artisan").returns(1)
      
      assert.is_true(laravel_helper.is_laravel_project())
    end)
    
    it("returns false when artisan file is not present", function()
      filereadable_mock.on_call_with("/test/project/artisan").returns(0)
      
      assert.is_false(laravel_helper.is_laravel_project())
    end)
  end)
end)
