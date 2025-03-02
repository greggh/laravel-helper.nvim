-- core_module_spec.lua
-- Tests for the core module in Laravel Helper

describe("core module", function()
  local core_module

  before_each(function()
    -- Reset the module
    package.loaded["laravel-helper.core"] = nil
    core_module = require("laravel-helper.core")

    -- Mock vim functions
    _G.vim = _G.vim or {}
    _G.vim.fn = _G.vim.fn or {}
    _G.vim.fn.getcwd = function()
      return "/test/laravel_project"
    end
    _G.vim.fn.filereadable = function(path)
      if path == "/test/laravel_project/artisan" then
        return 1
      end
      return 0
    end
    _G.vim.fn.fnamemodify = function(path, modifier)
      if modifier == ":h" then
        return "/test"
      end
      return path
    end
    _G.vim.api = _G.vim.api or {}
    _G.vim.api.nvim_get_current_buf = function()
      return 1
    end
    _G.vim.api.nvim_buf_get_name = function(bufnr)
      return "/test/laravel_project/app/test.php"
    end
  end)

  describe("find_laravel_root", function()
    it("should find laravel root in current directory", function()
      local result = core_module.find_laravel_root()
      assert.equals("/test/laravel_project", result)
    end)

    it("should return nil when not in a Laravel project", function()
      -- Override the filereadable mock for this test
      _G.vim.fn.filereadable = function(path)
        return 0
      end

      local result = core_module.find_laravel_root()
      assert.is_nil(result)
    end)

    it("should search parent directories for Laravel root", function()
      -- Setup mocks for recursive search
      _G.vim.api.nvim_get_current_buf = function()
        return 2
      end
      _G.vim.api.nvim_buf_get_name = function(bufnr)
        return "/test/laravel_project/app/Http/Controllers/TestController.php"
      end

      local file_checks = {}
      _G.vim.fn.filereadable = function(path)
        table.insert(file_checks, path)
        if path == "/test/laravel_project/artisan" then
          return 1
        end
        return 0
      end

      _G.vim.fn.fnamemodify = function(path, modifier)
        if modifier == ":h" then
          -- Simulate directory hierarchy
          if path == "/test/laravel_project/app/Http/Controllers/TestController.php" then
            return "/test/laravel_project/app/Http/Controllers"
          elseif path == "/test/laravel_project/app/Http/Controllers" then
            return "/test/laravel_project/app/Http"
          elseif path == "/test/laravel_project/app/Http" then
            return "/test/laravel_project/app"
          elseif path == "/test/laravel_project/app" then
            return "/test/laravel_project"
          elseif path == "/test/laravel_project" then
            return "/test"
          else
            return "/test"
          end
        end
        return path
      end

      local result = core_module.find_laravel_root()
      assert.equals("/test/laravel_project", result)

      -- Verify we checked multiple paths
      assert.is_true(#file_checks > 0)
    end)
  end)

  describe("is_laravel_project", function()
    it("should return true for Laravel projects", function()
      local result = core_module.is_laravel_project()
      assert.is_true(result)
    end)

    it("should return false for non-Laravel projects", function()
      -- Override the filereadable mock for this test
      _G.vim.fn.filereadable = function(path)
        return 0
      end

      local result = core_module.is_laravel_project()
      assert.is_false(result)
    end)
  end)

  describe("read_user_preference", function()
    it("should return nil for non-Laravel projects", function()
      local result = core_module.read_user_preference(nil)
      assert.is_nil(result)
    end)

    it("should return nil when preferences file doesn't exist", function()
      local result = core_module.read_user_preference("/test/laravel_project")
      assert.is_nil(result)
    end)

    it("should parse preferences file correctly", function()
      -- Mock readfile to return preferences
      _G.vim.fn.filereadable = function(path)
        if path == "/test/laravel_project/.nvim-helper" then
          return 1
        end
        return 0
      end

      _G.vim.fn.readfile = function(path)
        if path == "/test/laravel_project/.nvim-helper" then
          return {
            "# Neovim Helper Configuration",
            "ide_helper_install=declined",
            "use_standard_php=always",
          }
        end
        return {}
      end

      local result = core_module.read_user_preference("/test/laravel_project")
      assert.is_not_nil(result)
      assert.equals("declined", result["ide_helper_install"])
      assert.equals("always", result["use_standard_php"])
    end)
  end)

  describe("has_ide_helper", function()
    it("should detect IDE helper when installed", function()
      -- Mock readfile to simulate composer.json with Laravel IDE helper
      _G.vim.fn.filereadable = function(path)
        if path == "/test/laravel_project/artisan" or path == "/test/laravel_project/composer.json" then
          return 1
        end
        return 0
      end

      _G.vim.fn.readfile = function(path)
        if path == "/test/laravel_project/composer.json" then
          return {
            "{",
            '  "require-dev": {',
            '    "barryvdh/laravel-ide-helper": "^2.10"',
            "  }",
            "}",
          }
        end
        return {}
      end

      local result = core_module.has_ide_helper()
      assert.is_true(result)
    end)

    it("should return false when IDE helper is not installed", function()
      -- Mock readfile to simulate composer.json without Laravel IDE helper
      _G.vim.fn.filereadable = function(path)
        if path == "/test/laravel_project/artisan" or path == "/test/laravel_project/composer.json" then
          return 1
        end
        return 0
      end

      _G.vim.fn.readfile = function(path)
        if path == "/test/laravel_project/composer.json" then
          return {
            "{",
            '  "require-dev": {',
            '    "phpunit/phpunit": "^9.0"',
            "  }",
            "}",
          }
        end
        return {}
      end

      local result = core_module.has_ide_helper()
      assert.is_false(result)
    end)
  end)

  describe("has_docker_compose", function()
    it("should detect docker-compose.yml", function()
      -- Mock filereadable to detect docker-compose.yml
      _G.vim.fn.filereadable = function(path)
        if path == "/test/laravel_project/artisan" or path == "/test/laravel_project/docker-compose.yml" then
          return 1
        end
        return 0
      end

      local result = core_module.has_docker_compose()
      assert.is_true(result)
    end)

    it("should detect docker-compose.yaml", function()
      -- Mock filereadable to detect docker-compose.yaml
      _G.vim.fn.filereadable = function(path)
        if path == "/test/laravel_project/artisan" or path == "/test/laravel_project/docker-compose.yaml" then
          return 1
        end
        return 0
      end

      local result = core_module.has_docker_compose()
      assert.is_true(result)
    end)

    it("should return false when no docker-compose file exists", function()
      local result = core_module.has_docker_compose()
      assert.is_false(result)
    end)
  end)

  describe("has_sail", function()
    it("should detect Sail when installed", function()
      -- Mock executable and filereadable to detect sail script
      _G.vim.fn.filereadable = function(path)
        if path == "/test/laravel_project/artisan" or path == "/test/laravel_project/vendor/bin/sail" then
          return 1
        end
        return 0
      end

      _G.vim.fn.executable = function(path)
        if path == "/test/laravel_project/vendor/bin/sail" then
          return 1
        end
        return 0
      end

      local result = core_module.has_sail()
      assert.is_true(result)
    end)

    it("should return false when sail script doesn't exist", function()
      local result = core_module.has_sail()
      assert.is_false(result)
    end)

    it("should return false when sail script exists but is not executable", function()
      -- Mock filereadable to detect sail script but not executable
      _G.vim.fn.filereadable = function(path)
        if path == "/test/laravel_project/artisan" or path == "/test/laravel_project/vendor/bin/sail" then
          return 1
        end
        return 0
      end

      _G.vim.fn.executable = function(path)
        return 0
      end

      local result = core_module.has_sail()
      assert.is_false(result)
    end)
  end)

  describe("ide_helper_files_exist", function()
    it("should detect IDE helper files", function()
      -- Mock filereadable to detect IDE helper files
      _G.vim.fn.filereadable = function(path)
        if path == "/test/laravel_project/artisan" or path == "/test/laravel_project/_ide_helper.php" then
          return 1
        end
        return 0
      end

      local result = core_module.ide_helper_files_exist()
      assert.is_true(result)
    end)

    it("should detect model helper files", function()
      -- Mock filereadable to detect model helper files
      _G.vim.fn.filereadable = function(path)
        if path == "/test/laravel_project/artisan" or path == "/test/laravel_project/_ide_helper_models.php" then
          return 1
        end
        return 0
      end

      local result = core_module.ide_helper_files_exist()
      assert.is_true(result)
    end)

    it("should detect PhpStorm meta files", function()
      -- Mock filereadable to detect PhpStorm meta files
      _G.vim.fn.filereadable = function(path)
        if path == "/test/laravel_project/artisan" or path == "/test/laravel_project/.phpstorm.meta.php" then
          return 1
        end
        return 0
      end

      local result = core_module.ide_helper_files_exist()
      assert.is_true(result)
    end)

    it("should return false when no IDE helper files exist", function()
      local result = core_module.ide_helper_files_exist()
      assert.is_false(result)
    end)
  end)
end)
