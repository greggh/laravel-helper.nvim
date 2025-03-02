-- health_check_spec.lua
-- Tests for health check functionality in Laravel Helper

describe("health check", function()
  local health_module
  local health_start_called = false
  local health_ok_calls = {}
  local health_warn_calls = {}
  local health_error_calls = {}
  local health_info_calls = {}

  before_each(function()
    -- Reset tracking variables
    health_start_called = false
    health_ok_calls = {}
    health_warn_calls = {}
    health_error_calls = {}
    health_info_calls = {}

    -- Mock vim executable check
    _G.vim = _G.vim or {}
    _G.vim.fn = _G.vim.fn or {}
    _G.vim.fn.executable = function(cmd)
      if cmd == "php" then
        return 1
      elseif cmd == "composer" then
        return 1
      end
      return 0
    end

    -- Mock vim.health
    _G.vim.health = {
      start = function(report_name)
        health_start_called = true
        return true
      end,

      ok = function(message)
        table.insert(health_ok_calls, message)
        return true
      end,

      warn = function(message, suggestions)
        table.insert(health_warn_calls, {
          message = message,
          suggestions = suggestions,
        })
        return true
      end,

      error = function(message, suggestions)
        table.insert(health_error_calls, {
          message = message,
          suggestions = suggestions,
        })
        return true
      end,

      info = function(message, suggestions)
        if type(message) == "string" then
          table.insert(health_info_calls, message)
        end
        return true
      end,
    }

    -- Mock mega.cmdparse
    package.loaded["mega.cmdparse"] = {}

    -- Mock core module functions needed by health check
    _G.original_core_module = package.loaded["laravel-helper.core"]
    package.loaded["laravel-helper.core"] = {
      debug_mode = false,
      find_laravel_root = function()
        return "/test/laravel_project"
      end,
      is_laravel_project = function()
        return true
      end,
      is_ide_helper_installed = function()
        return true
      end,
      has_sail = function()
        return true
      end,
    }

    -- Load health module
    package.loaded["laravel-helper.health"] = nil
    health_module = require("laravel-helper.health")
  end)

  after_each(function()
    -- Restore original core module if it existed
    if _G.original_core_module then
      package.loaded["laravel-helper.core"] = _G.original_core_module
    else
      package.loaded["laravel-helper.core"] = nil
    end

    -- Clean up mock
    package.loaded["mega.cmdparse"] = nil
  end)

  describe("check", function()
    it("should start a health report", function()
      health_module.check()
      assert.is_true(health_start_called, "Health report should be started")
    end)

    it("should report PHP installation", function()
      health_module.check()

      local php_ok = false
      for _, message in ipairs(health_ok_calls) do
        if message:match("PHP is installed") then
          php_ok = true
          break
        end
      end

      assert.is_true(php_ok, "Should report PHP as installed")
    end)

    it("should report Composer installation", function()
      health_module.check()

      local composer_ok = false
      for _, message in ipairs(health_ok_calls) do
        if message:match("Composer is installed") then
          composer_ok = true
          break
        end
      end

      assert.is_true(composer_ok, "Should report Composer as installed")
    end)

    it("should report missing Composer as warning", function()
      -- Override the executable check for composer
      _G.vim.fn.executable = function(cmd)
        if cmd == "php" then
          return 1
        elseif cmd == "composer" then
          return 0
        end
        return 0
      end

      health_module.check()

      local composer_warning = false
      for _, warning in ipairs(health_warn_calls) do
        if warning.message:match("Composer is not installed") then
          composer_warning = true
          break
        end
      end

      assert.is_true(composer_warning, "Should report missing Composer as warning")
    end)

    it("should report IDE Helper installation", function()
      health_module.check()

      local ide_helper_ok = false
      for _, message in ipairs(health_ok_calls) do
        if message:match("Laravel IDE Helper is installed") then
          ide_helper_ok = true
          break
        end
      end

      assert.is_true(ide_helper_ok, "Should report Laravel IDE Helper as installed")
    end)

    it("should report missing IDE Helper as info", function()
      -- Override the mock to return false
      package.loaded["laravel-helper.core"].is_ide_helper_installed = function()
        return false
      end

      health_module.check()

      local ide_helper_info = false
      for _, info in ipairs(health_info_calls) do
        if info:match("Laravel IDE Helper is not installed") then
          ide_helper_info = true
          break
        end
      end

      assert.is_true(ide_helper_info, "Should report missing IDE Helper as info")
    end)

    it("should report Laravel Sail availability", function()
      health_module.check()

      local sail_ok = false
      for _, message in ipairs(health_ok_calls) do
        if message:match("Laravel Sail is available") then
          sail_ok = true
          break
        end
      end

      assert.is_true(sail_ok, "Should report Laravel Sail as available")
    end)

    it("should report Sail not available as info", function()
      -- Override the mock to return false
      package.loaded["laravel-helper.core"].has_sail = function()
        return false
      end

      health_module.check()

      local sail_info = false
      for _, info in ipairs(health_info_calls) do
        if info:match("Laravel Sail is not available") then
          sail_info = true
          break
        end
      end

      assert.is_true(sail_info, "Should report Sail not available as info")
    end)

    it("should report not in Laravel project when appropriate", function()
      -- Override the mock to return false
      package.loaded["laravel-helper.core"].is_laravel_project = function()
        return false
      end

      health_module.check()

      local not_laravel = false
      for _, info in ipairs(health_info_calls) do
        if info:match("not a Laravel project") then
          not_laravel = true
          break
        end
      end

      assert.is_true(not_laravel, "Should report not in Laravel project")
    end)
  end)
end)
