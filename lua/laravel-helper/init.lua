local M = {}

-- Default configuration
M.config = {
  -- Whether to automatically detect Laravel projects and offer IDE Helper generation
  auto_detect = true,
  
  -- Default timeout for Sail/Docker operations (in milliseconds)
  docker_timeout = 360000, -- 6 minutes
  
  -- Whether to automatically use Sail when available
  prefer_sail = true,
  
  -- Commands to run for IDE Helper generation
  commands = {
    "ide-helper:generate",    -- PHPDoc generation for Laravel classes
    "ide-helper:models -N",   -- PHPDoc generation for models (no write)
    "ide-helper:meta",        -- PhpStorm Meta file generation
  }
}

-- Require core functionality
M.core = require("laravel-helper.core")

-- Helper to check if we're in a Laravel project
function M.is_laravel_project()
  return M.core.find_laravel_root() ~= nil
end

-- Setup function to configure the plugin
function M.setup(user_config)
  -- Merge user config with defaults
  if user_config then
    M.config = vim.tbl_deep_extend("force", M.config, user_config)
  end
  
  -- Initialize the core functionality
  M.core.setup(M.config)
  
  -- If auto-detect is enabled, set up BufEnter autocmd
  if M.config.auto_detect then
    M.setup_auto_detection()
  end
  
  return M
end

-- Set up automatic detection of Laravel projects
function M.setup_auto_detection()
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
function M.install_ide_helper()
  return M.core.install_ide_helper()
end

-- Generate IDE Helper files in the current project
function M.generate_ide_helper(force, use_sail)
  return M.core.generate_ide_helper(force, use_sail)
end

-- Toggle debug mode
function M.toggle_debug_mode()
  return M.core.toggle_debug_mode()
end

-- Run an Artisan command with UI prompt
function M.run_artisan_command(command)
  if not command then
    -- If no command was provided, prompt the user
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
function M.find_laravel_root()
  return M.core.find_laravel_root()
end

-- Use Sail to run a command if available, otherwise use PHP
function M.with_sail_or_php(cmd)
  return M.core.with_sail_or_php(cmd)
end

-- Get the command to run with either Sail or standard PHP
function M.get_sail_or_php_command(cmd)
  local result = M.core.with_sail_or_php(cmd)
  if result then
    return result.command
  end
  return nil
end

-- Forward other calls to core module
setmetatable(M, {
  __index = function(_, key)
    return M.core[key]
  end
})

return M