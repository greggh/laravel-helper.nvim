-- command_registration_spec.lua
-- Tests for command registration in Laravel Helper

describe("command registration", function()
  local commands_module
  local registered_commands = {}
  local registered_autocmds = {}

  before_each(function()
    -- Reset command and autocmd registrations
    registered_commands = {}
    registered_autocmds = {}

    -- Mock vim functions
    _G.vim = _G.vim or {}
    _G.vim.api = _G.vim.api or {}
    _G.vim.api.nvim_create_user_command = function(name, callback, opts)
      table.insert(registered_commands, {
        name = name,
        callback = callback,
        opts = opts,
      })
      return true
    end

    _G.vim.api.nvim_create_autocmd = function(event, opts)
      table.insert(registered_autocmds, {
        event = event,
        opts = opts,
      })
      return 1
    end

    -- Mock vim.notify
    _G.vim.notify = function() end

    -- Mock vim.api.nvim_command
    _G.vim.api.nvim_command = function() end

    -- Mock mega.cmdparse
    package.loaded["mega.cmdparse"] = {
      ParameterParser = {
        new = function()
          return {
            add_subparsers = function()
              return {
                add_parser = function()
                  return {
                    add_parameter = function()
                      return {}
                    end,
                    set_execute = function()
                      return {}
                    end,
                    add_subparsers = function()
                      return {
                        add_parser = function()
                          return {
                            add_parameter = function()
                              return {}
                            end,
                            set_execute = function()
                              return {}
                            end,
                          }
                        end,
                      }
                    end,
                  }
                end,
              }
            end,
          }
        end,
      },
      create_user_command = function() end,
    }

    -- Mock core module
    _G.original_core_module = package.loaded["laravel-helper.core"]
    package.loaded["laravel-helper.core"] = {
      setup_auto_ide_helper = function() end,
      find_laravel_root = function()
        return "/test/laravel_project"
      end,
      has_ide_helper = function()
        return true
      end,
      generate_ide_helper = function()
        return true
      end,
      install_ide_helper = function()
        return true
      end,
      run_artisan_command = function()
        return true
      end,
      toggle_debug_mode = function()
        return true
      end,
      debug_mode = false,
      debug_ide_helper_state = function() end,
    }

    -- Reset and load commands module
    package.loaded["laravel-helper.commands"] = nil
    commands_module = require("laravel-helper.commands")
  end)

  after_each(function()
    -- Restore original core module if it existed
    if _G.original_core_module then
      package.loaded["laravel-helper.core"] = _G.original_core_module
    else
      package.loaded["laravel-helper.core"] = nil
    end

    -- Clean up mock for mega.cmdparse
    package.loaded["mega.cmdparse"] = nil
  end)

  describe("setup_commands", function()
    it("should register LaravelGenerateIDEHelper command", function()
      commands_module.setup_commands()

      local command_registered = false
      for _, cmd in ipairs(registered_commands) do
        if cmd.name == "LaravelGenerateIDEHelper" then
          command_registered = true
          break
        end
      end

      assert.is_true(command_registered, "LaravelGenerateIDEHelper command should be registered")
    end)

    it("should register LaravelInstallIDEHelper command", function()
      commands_module.setup_commands()

      local command_registered = false
      for _, cmd in ipairs(registered_commands) do
        if cmd.name == "LaravelInstallIDEHelper" then
          command_registered = true
          break
        end
      end

      assert.is_true(command_registered, "LaravelInstallIDEHelper command should be registered")
    end)

    it("should register LaravelArtisan command", function()
      commands_module.setup_commands()

      local command_registered = false
      for _, cmd in ipairs(registered_commands) do
        if cmd.name == "LaravelArtisan" then
          command_registered = true
          assert.is_not_nil(cmd.opts.nargs, "LaravelArtisan should accept arguments")
          break
        end
      end

      assert.is_true(command_registered, "LaravelArtisan command should be registered")
    end)

    it("should register LaravelIDEHelperToggleDebug command", function()
      commands_module.setup_commands()

      local command_registered = false
      for _, cmd in ipairs(registered_commands) do
        if cmd.name == "LaravelIDEHelperToggleDebug" then
          command_registered = true
          break
        end
      end

      assert.is_true(command_registered, "LaravelIDEHelperToggleDebug command should be registered")
    end)
  end)

  describe("command behavior with options", function()
    it("should accept PHP mode for IDE Helper generation", function()
      -- Mock vim.api.nvim_command to capture the command
      local command_executed = nil
      _G.vim.api.nvim_command = function(cmd)
        command_executed = cmd
      end

      commands_module.setup_commands()

      -- Find the command and execute it with "php" argument
      for _, cmd in ipairs(registered_commands) do
        if cmd.name == "LaravelGenerateIDEHelper" then
          -- Mock the command invocation with PHP mode
          local opts = { args = "php" }
          cmd.callback(opts)
          break
        end
      end

      assert.is_not_nil(command_executed, "api.nvim_command should have been called")
      assert.truthy(
        string.find(command_executed, "Laravel ide%-helper generate"),
        "Command should use ide-helper generate"
      )
      assert.falsy(string.find(command_executed, "%-%-use%-sail"), "Command should not use sail option")
    end)

    it("should accept Sail mode for IDE Helper generation", function()
      -- Mock vim.api.nvim_command to capture the command
      local command_executed = nil
      _G.vim.api.nvim_command = function(cmd)
        command_executed = cmd
      end

      commands_module.setup_commands()

      -- Find the command and execute it with "sail" argument
      for _, cmd in ipairs(registered_commands) do
        if cmd.name == "LaravelGenerateIDEHelper" then
          -- Mock the command invocation with Sail mode
          local opts = { args = "sail" }
          cmd.callback(opts)
          break
        end
      end

      assert.is_not_nil(command_executed, "api.nvim_command should have been called")
      assert.truthy(
        string.find(command_executed, "Laravel ide%-helper generate"),
        "Command should use ide-helper generate"
      )
      assert.truthy(string.find(command_executed, "%-%-use%-sail"), "Command should use sail option")
    end)
  end)
end)
