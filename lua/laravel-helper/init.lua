---@mod laravel-helper Laravel Helper for Neovim
---@brief [[
--- A plugin to enhance Laravel development in Neovim
--- Provides IDE helper integration, artisan commands, and more.
---@brief ]]

--- @table M
--- The main Laravel Helper module
--- @field setup function Configure the plugin
--- @field version table Version information
--- @field core table Core functionality module

local M = {}

-- Require core functionality lazily
M.core = nil

-- Helper to check if we're in a Laravel project
---@return boolean
function M.is_laravel_project()
  -- Lazily load core module when needed
  if not M.core then
    M.core = require("laravel-helper.core")
  end
  return M.core.find_laravel_root() ~= nil
end

-- Check if telescope is available
local function has_telescope()
  return pcall(require, "telescope")
end

-- Setup function to configure the plugin
---@param user_config? table User configuration
---@return LaravelHelper
function M.setup(user_config)
  -- Load version information
  M.version = require("laravel-helper.version")

  -- Load and validate configuration
  local config_module = require("laravel-helper.config")
  local config, is_valid, error_message = config_module.merge(user_config)

  if not is_valid then
    vim.notify("Laravel Helper: " .. error_message, vim.log.levels.ERROR)
    return M
  end

  -- Store validated config
  M.config = config

  -- Lazily load core module
  if not M.core then
    M.core = require("laravel-helper.core")
  end

  -- Initialize the core functionality
  M.core.setup(M.config)

  -- If auto-detect is enabled, set up BufEnter autocmd
  if M.config.auto_detect then
    M.setup_auto_detection()
  end

  -- Only setup commands if mega.cmdparse is available
  local has_mega_cmdparse, _ = pcall(require, "mega.cmdparse")
  if has_mega_cmdparse then
    -- Setup the new command structure
    local commands = require("laravel-helper.commands")
    commands.setup_commands()
  else
    -- Fall back to old command structure
    M.core.setup_auto_ide_helper()

    -- Warn the user about missing mega.cmdparse
    vim.notify(
      string.format(
        "Laravel Helper v%s: mega.cmdparse not found. Using legacy commands. "
          .. "Install ColinKennedy/mega.cmdparse for enhanced command experience.",
        M.version.string()
      ),
      vim.log.levels.WARN
    )
  end

  -- Setup Telescope integration if available
  if has_telescope() then
    -- First load telescope
    local telescope = require("telescope")
    -- Then setup our module
    local telescope_module = require("laravel-helper.telescope")
    telescope_module.setup(M.core)

    -- Register extension and check it's available
    vim.defer_fn(function()
      if telescope.extensions and telescope.extensions.laravel then
        -- Extension is registered successfully
        vim.notify("Laravel Telescope extension registered successfully", vim.log.levels.DEBUG)
      else
        -- Extension didn't register properly, notify in debug mode
        vim.notify("Laravel Telescope extension not registered properly", vim.log.levels.DEBUG)
      end
    end, 100)

    -- Override the run_artisan_command to use Telescope when available
    telescope_module.override_artisan_command(M.core)

    -- Add mapping to M for direct access
    M.telescope = telescope_module

    -- Add user command for Laravel Telescope extension
    vim.api.nvim_create_user_command("LaravelTelescope", function(opts)
      local subcmd = opts.args and opts.args ~= "" and opts.args or "artisan"

      -- Make sure the extension is properly registered
      local has_laravel_ext, telescope_ext = pcall(function()
        return require("telescope").extensions.laravel
      end)

      if not has_laravel_ext or not telescope_ext then
        vim.notify("Laravel Telescope extension not properly registered. Try restarting Neovim.", vim.log.levels.ERROR)
        return
      end

      if subcmd == "artisan" then
        telescope_ext.artisan()
      elseif subcmd == "routes" then
        telescope_ext.routes()
      elseif subcmd == "models" then
        telescope_ext.models()
      else
        vim.notify("Unknown Laravel Telescope command: " .. subcmd, vim.log.levels.WARN)
      end
    end, {
      desc = "Laravel Telescope commands",
      nargs = "?",
      complete = function()
        return { "artisan", "routes", "models" }
      end,
    })
  end

  -- Log plugin initialization
  if vim.fn.exists("*luapad#log") == 1 then
    vim.fn["luapad#log"](string.format("Laravel Helper v%s initialized", M.version.string()))
  end

  return M
end

-- Set up automatic detection of Laravel projects
---@return nil
function M.setup_auto_detection()
  -- Ensure core module is loaded
  if not M.core then
    M.core = require("laravel-helper.core")
  end

  -- Initialize state variables if not already initialized
  if not vim.g.laravel_ide_helper_checked then
    vim.g.laravel_ide_helper_checked = {}
  end

  vim.api.nvim_create_autocmd("BufEnter", {
    pattern = "*.php",
    callback = function()
      M.core.check_laravel_project()
    end,
  })
end

-- Install IDE Helper in the current project
---@return boolean success
function M.install_ide_helper()
  if not M.core then
    M.core = require("laravel-helper.core")
  end
  return M.core.install_ide_helper()
end

-- Generate IDE Helper files in the current project
---@param force boolean Force generation even if already exists
---@param use_sail? boolean Use Laravel Sail instead of PHP
---@return boolean success
function M.generate_ide_helper(force, use_sail)
  if not M.core then
    M.core = require("laravel-helper.core")
  end
  return M.core.generate_ide_helper(force, use_sail)
end

-- Toggle debug mode
---@return boolean debug_mode Current debug mode state
function M.toggle_debug_mode()
  if not M.core then
    M.core = require("laravel-helper.core")
  end
  return M.core.toggle_debug_mode()
end

-- Run an Artisan command with UI prompt
---@param command? string Artisan command to run
---@return nil
function M.run_artisan_command(command)
  if not M.core then
    M.core = require("laravel-helper.core")
  end

  if not command then
    -- If Telescope is available, use it for command selection
    if has_telescope() then
      require("telescope").extensions.laravel.artisan()
      return
    end

    -- Otherwise, fall back to vim.ui.input
    vim.ui.input({
      prompt = "Artisan command: ",
      default = "route:list",
    }, function(input)
      if input and input ~= "" then
        M.run_artisan_command(input)
      end
    end)
    return
  end

  -- If command was provided, pass it directly to core
  return M.core.run_artisan_command(command)
end

-- Check if this is a Laravel project
---@return string|nil Laravel root directory or nil
function M.find_laravel_root()
  if not M.core then
    M.core = require("laravel-helper.core")
  end
  return M.core.find_laravel_root()
end

-- Use Sail to run a command if available, otherwise use PHP
---@param cmd string Command to run
---@return table|nil Command parameters
function M.with_sail_or_php(cmd)
  if not M.core then
    M.core = require("laravel-helper.core")
  end
  return M.core.with_sail_or_php(cmd)
end

-- Get the command to run with either Sail or standard PHP
---@param cmd string Command to run
---@return string|nil Command string
function M.get_sail_or_php_command(cmd)
  if not M.core then
    M.core = require("laravel-helper.core")
  end
  local result = M.core.with_sail_or_php(cmd)
  if result then
    return result.command
  end
  return nil
end

-- Instead of using metatable forwarding, we'll explicitly define the functions we want to expose
-- This avoids any potential metatable recursion issues

-- Ensure core module is loaded before use
local function ensure_core()
  if not M.core then
    M.core = require("laravel-helper.core")
  end
  return M.core
end

-- Explicitly define functions that should be forwarded to core
function M.find_laravel_root()
  return ensure_core().find_laravel_root()
end

function M.has_sail()
  return ensure_core().has_sail()
end

function M.is_ide_helper_installed()
  return ensure_core().has_ide_helper()
end

function M.is_sail_running()
  return ensure_core().is_sail_running()
end

function M.check_laravel_project()
  return ensure_core().check_laravel_project()
end

function M.debug_ide_helper_state()
  return ensure_core().debug_ide_helper_state()
end

return M
