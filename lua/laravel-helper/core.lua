-- Core functionality for Laravel Helper
local M = {}

-- Enable to show detailed Laravel IDE Helper debug output
M.debug_mode = false

-- Detect if the current project is a Laravel project
function M.find_laravel_root()
  -- Start with current working directory
  local current_dir = vim.fn.getcwd()
  
  if M.debug_mode then
    vim.notify("Looking for Laravel project, starting at: " .. current_dir, vim.log.levels.DEBUG)
  end
  
  -- Check if current directory is already the Laravel root
  if vim.fn.filereadable(current_dir .. "/artisan") == 1 then
    if M.debug_mode then
      vim.notify("Found Laravel project at current directory: " .. current_dir, vim.log.levels.DEBUG)
    end
    return current_dir
  end
  
  -- If current buffer is a file, use its directory as starting point
  local current_buf = vim.api.nvim_get_current_buf()
  local file_path = vim.api.nvim_buf_get_name(current_buf)
  
  if M.debug_mode then
    vim.notify("Current buffer file path: " .. (file_path or "none"), vim.log.levels.DEBUG)
  end
  
  if file_path and file_path ~= "" then
    local file_dir = vim.fn.fnamemodify(file_path, ":h")
    if file_dir and file_dir ~= "" then
      current_dir = file_dir
      if M.debug_mode then
        vim.notify("Using file directory as search starting point: " .. current_dir, vim.log.levels.DEBUG)
      end
    end
  end
  
  -- Recursively check parent directories for artisan file
  local max_depth = 10 -- Avoid infinite loop
  local depth = 0
  local dir = current_dir
  
  if M.debug_mode then
    vim.notify("Starting recursive search for Laravel root from: " .. dir, vim.log.levels.DEBUG)
  end
  
  while depth < max_depth do
    local artisan_path = dir .. "/artisan"
    if M.debug_mode then
      vim.notify("Checking for artisan at: " .. artisan_path, vim.log.levels.DEBUG)
    end
    
    if vim.fn.filereadable(artisan_path) == 1 then
      if M.debug_mode then
        vim.notify("Found Laravel root at: " .. dir, vim.log.levels.DEBUG)
      end
      return dir -- Found Laravel root
    end
    
    -- Go up one directory
    local parent_dir = vim.fn.fnamemodify(dir, ":h")
    if parent_dir == dir then
      if M.debug_mode then
        vim.notify("Reached filesystem root, stopping search", vim.log.levels.DEBUG)
      end
      break -- Reached root directory, stop searching
    end
    dir = parent_dir
    depth = depth + 1
    if M.debug_mode then
      vim.notify("Moving up to parent directory: " .. dir, vim.log.levels.DEBUG)
    end
  end
  
  if M.debug_mode then
    vim.notify("No Laravel project found after searching " .. depth .. " parent directories", vim.log.levels.DEBUG)
  end
  return nil -- Not a Laravel project
end

-- Check if this is a Laravel project
function M.is_laravel_project()
  return M.find_laravel_root() ~= nil
end

-- Read user preferences from the .nvim-helper file
function M.read_user_preference(laravel_root)
  if not laravel_root then
    return nil
  end
  
  local prefs_file = laravel_root .. "/.nvim-helper"
  if vim.fn.filereadable(prefs_file) ~= 1 then
    return nil
  end
  
  local content = vim.fn.readfile(prefs_file)
  local prefs = {}
  
  for _, line in ipairs(content) do
    local key, value = line:match("([^=]+)=(.+)")
    if key and value then
      prefs[key:gsub("^%s*(.-)%s*$", "%1")] = value:gsub("^%s*(.-)%s*$", "%1")
    end
  end
  
  return prefs
end

-- Save user preferences to the .nvim-helper file
function M.save_user_preference(laravel_root, key, value)
  if not laravel_root then
    return false, "No Laravel root directory specified"
  end
  
  -- Check if directory exists and is writable
  if vim.fn.isdirectory(laravel_root) ~= 1 then
    return false, "Laravel root directory does not exist: " .. laravel_root
  end
  
  if vim.fn.filewritable(laravel_root) ~= 2 then
    return false, "Laravel root directory is not writable: " .. laravel_root
  end
  
  local prefs_file = laravel_root .. "/.nvim-helper"
  local prefs = M.read_user_preference(laravel_root) or {}
  
  -- Update or add the preference
  prefs[key] = value
  
  -- Header with explanation of the file format and available settings
  local header = {
    "# Neovim Helper Configuration for Laravel Projects",
    "# This file stores your preferences for Neovim's Laravel integration.",
    "# ",
    "# Available settings:",
    "# - ide_helper_install=declined   (Skip prompts to install Laravel IDE Helper)",
    "# - ide_helper_generate=declined  (Skip prompts to generate helper files)",
    "# - use_standard_php=always       (Always use standard PHP instead of Sail)",
    "# ",
    "# To change a setting, edit the value or remove the line to reset to default behavior.",
    "# Example: Change 'declined' to 'prompt' to start getting prompts again.",
    "# "
  }
  
  -- Convert preferences back to file format
  local lines = {}
  
  -- Only add header if creating a new file or the file doesn't have our header
  if vim.fn.filereadable(prefs_file) ~= 1 or 
     not vim.fn.readfile(prefs_file, "", 1)[1] or
     not vim.fn.readfile(prefs_file, "", 1)[1]:match("^# Neovim Helper Configuration") then
    for _, line in ipairs(header) do
      table.insert(lines, line)
    end
  end
  
  -- Add actual preference key-value pairs
  for k, v in pairs(prefs) do
    table.insert(lines, k .. "=" .. v)
  end
  
  -- Try to write to file and capture result
  local result = vim.fn.writefile(lines, prefs_file)
  if result == 0 then
    return true
  else
    local error_msg
    if vim.fn.filewritable(prefs_file) == 1 then
      error_msg = "File exists but is not writable: " .. prefs_file
    elseif vim.fn.filewritable(laravel_root) ~= 2 then
      error_msg = "Directory is not writable: " .. laravel_root
    else
      error_msg = "Failed to write to file (code: " .. result .. ")"
    end
    return false, error_msg
  end
end

-- Check if IDE Helper is declined
function M.is_ide_helper_declined(laravel_root)
  local prefs = M.read_user_preference(laravel_root)
  if not prefs then
    return false
  end
  
  return prefs["ide_helper_install"] == "declined"
end

-- Check a Laravel project for IDE Helper status
function M.check_laravel_project()
  -- Get the Laravel root if it exists
  local laravel_root = M.find_laravel_root()
  if not laravel_root then 
    if M.debug_mode then
      vim.notify("Not a Laravel project, skipping IDE Helper check", vim.log.levels.DEBUG)
    end
    return 
  end
  
  -- Initialize state variables if necessary
  vim.g.laravel_ide_helper_checked = vim.g.laravel_ide_helper_checked or {}
  
  -- First make sure this isn't a duplicate in the same Neovim instance
  if vim.g.laravel_ide_helper_checked[laravel_root] then 
    if M.debug_mode then
      vim.notify("Already checked Laravel project at: " .. laravel_root, vim.log.levels.DEBUG)
    end
    return 
  end
  
  -- Mark this project as checked to avoid multiple prompts in this session
  vim.g.laravel_ide_helper_checked[laravel_root] = true
  if M.debug_mode then
    vim.notify("Marked Laravel project as checked: " .. laravel_root, vim.log.levels.DEBUG)
  end
  
  -- For now, just a minimal implementation that stores that we've checked this project
  -- The full implementation will be added in stages
  return
end

-- Simple function to check if IDE Helper is installed
function M.has_ide_helper()
  local laravel_root = M.find_laravel_root()
  if not laravel_root then
    return false
  end
  
  -- Check for the package in composer.json
  if vim.fn.filereadable(laravel_root .. "/composer.json") == 1 then
    local composer_json = vim.fn.readfile(laravel_root .. "/composer.json")
    local composer_content = table.concat(composer_json, "\n")
    if composer_content:find("barryvdh/laravel%-ide%-helper") then
      return true
    end
  end
  return false
end

-- Check if Sail is available
function M.has_sail()
  local laravel_root = M.find_laravel_root()
  if not laravel_root then
    return false
  end
  
  -- Check if the Sail script exists and is executable
  local sail_path = laravel_root .. "/vendor/bin/sail"
  return vim.fn.filereadable(sail_path) == 1 and vim.fn.executable(sail_path) == 1
end

-- Handle remembering user choices
function M.handle_remember_choice(laravel_root, pref_key, pref_value, prompt_text, success_message)
  local remember_choice = vim.fn.confirm(
    prompt_text or "Would you like to remember this choice for this Laravel project?",
    "&Yes\n&No",
    2 -- Default to No
  )
  
  if remember_choice == 1 then
    -- Save the preference to the .nvim-helper file
    local success, error_msg = M.save_user_preference(laravel_root, pref_key, pref_value)
    if success then
      vim.notify(
        success_message or "Preference saved in .nvim-helper. To enable prompts again, change value to 'prompt' or delete the line.",
        vim.log.levels.INFO,
        { title = "Laravel IDE Helper" }
      )
    else
      vim.notify(
        "Failed to save preference: " .. (error_msg or "Unknown error"),
        vim.log.levels.WARN,
        { title = "Laravel IDE Helper" }
      )
    end
    
    return true
  end
  
  return false
end

-- Check if this is a production environment
function M.is_production_environment()
  local laravel_root = M.find_laravel_root()
  if not laravel_root then
    return false -- Not a Laravel project
  end
  
  -- First check for .env file which should contain APP_ENV
  local env_file = laravel_root .. "/.env"
  if vim.fn.filereadable(env_file) == 1 then
    local env_content = vim.fn.readfile(env_file)
    for _, line in ipairs(env_content) do
      -- Look for APP_ENV=production (ignoring whitespace and case)
      if line:lower():match("^%s*app_env%s*=%s*production%s*$") then
        return true
      end
    end
  end
  
  -- If .env doesn't indicate production, check config/app.php as a fallback
  local app_config = laravel_root .. "/config/app.php"
  if vim.fn.filereadable(app_config) == 1 then
    local config_content = vim.fn.readfile(app_config)
    local env_line_found = false
    for _, line in ipairs(config_content) do
      -- Look for 'env' => 'production' (case insensitive)
      local line_lower = line:lower()
      if line_lower:match("'env'%s*=>%s*'production'") or 
         line_lower:match('"env"%s*=>%s*"production"') then
        return true
      end
    end
  end
  
  return false -- Default to assuming it's not production
end

-- Check if IDE Helper files exist
function M.ide_helper_files_exist()
  local laravel_root = M.find_laravel_root()
  if not laravel_root then
    return false
  end
  
  -- Check for the main IDE helper files
  local files = {
    laravel_root .. "/_ide_helper.php",
    laravel_root .. "/_ide_helper_models.php",
    laravel_root .. "/.phpstorm.meta.php"
  }
  
  for _, file in ipairs(files) do
    if vim.fn.filereadable(file) == 1 then
      return true
    end
  end
  return false
end

-- Check for Docker availability
function M.is_docker_available()
  -- First check if docker is installed
  if vim.fn.executable("docker") ~= 1 then
    return false
  end
  
  -- Then check if docker daemon is running
  local result = vim.fn.system("docker info 2>/dev/null")
  local exit_code = vim.v.shell_error
  
  return exit_code == 0
end

-- Check if Sail is running
function M.is_sail_running()
  local laravel_root = M.find_laravel_root()
  if not laravel_root or not M.has_sail() then
    return false
  end
  
  -- A reliable way to check if Sail is running by checking Docker containers
  local cmd = "docker ps --format '{{.Names}}' | grep -q 'laravel\\.test\\|sail'"
  local exit_code = os.execute(cmd)
  
  -- os.execute returns true (and exit code 0) if the command succeeds
  return exit_code == 0 or exit_code == true
end

-- Check if user preferences indicate standard PHP should be used
function M.prefer_standard_php(laravel_root)
  local prefs = M.read_user_preference(laravel_root)
  if not prefs then
    return false
  end
  
  return prefs["use_standard_php"] == "always"
end

-- Setup nui.nvim popup
M.ide_helper_window = {
  popup = nil,
  lines = {},
  mounted = false,
  logger = function(message) 
    -- Minimal logger function
    if type(message) == "table" then
      vim.notify(table.concat(message, "\n"))
    elseif type(message) == "string" then
      vim.notify(message)
    end
  end
}

-- Minimal implementation of IDE Helper window
function M.show_ide_helper_window(title)
  -- Minimal implementation that defaults to vim.notify
  vim.notify("Laravel IDE Helper: " .. (title or ""), vim.log.levels.INFO)
  return M.ide_helper_window
end

-- Minimal implementation of buffer logger
function M.create_buffer_logger()
  return function(message)
    if not message then return end
    
    if type(message) == "table" then
      vim.notify(table.concat(message, "\n"))
    elseif type(message) == "string" then
      vim.notify(message)
    end
  end
end

-- Generate IDE Helper stubs (minimal implementation)
function M.generate_ide_helper(force)
  vim.notify("Generate IDE Helper called with force=" .. tostring(force), vim.log.levels.INFO)
  
  -- For now, just notify about what would happen
  local laravel_root = M.find_laravel_root()
  if not laravel_root then
    vim.notify("Not a Laravel project", vim.log.levels.WARN)
    return false
  end
  
  if not force and M.ide_helper_files_exist() then
    vim.notify("IDE Helper files already exist. Use force=true to regenerate.", 
             vim.log.levels.INFO, { title = "Laravel IDE Helper" })
    return true
  end
  
  if not M.has_ide_helper() then
    vim.notify("Laravel IDE Helper is not installed. Please install it first.", 
             vim.log.levels.INFO, { title = "Laravel IDE Helper" })
    return false
  end
  
  vim.notify("Would generate IDE Helper files for Laravel project at: " .. laravel_root, 
           vim.log.levels.INFO, { title = "Laravel IDE Helper" })
  return true
end

-- Install IDE Helper package (minimal implementation)
function M.install_ide_helper()
  vim.notify("Install IDE Helper called", vim.log.levels.INFO)
  
  -- For now, just notify about what would happen
  local laravel_root = M.find_laravel_root()
  if not laravel_root then
    vim.notify("Not a Laravel project", vim.log.levels.WARN)
    return false
  end
  
  if M.has_ide_helper() then
    vim.notify("Laravel IDE Helper is already installed", 
             vim.log.levels.INFO, { title = "Laravel IDE Helper" })
    return true
  end
  
  vim.notify("Would install Laravel IDE Helper in project at: " .. laravel_root, 
           vim.log.levels.INFO, { title = "Laravel IDE Helper" })
  return true
end

-- Toggle debug mode
function M.toggle_debug_mode()
  M.debug_mode = not M.debug_mode
  vim.notify("Laravel IDE Helper debug mode: " .. (M.debug_mode and "ENABLED" or "DISABLED"), 
           vim.log.levels.INFO, { title = "Laravel IDE Helper" })
  return M.debug_mode
end

-- Run an Artisan command (minimal implementation)
function M.run_artisan_command(command)
  if not command then
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
  
  local laravel_root = M.find_laravel_root()
  if not laravel_root then
    vim.notify("Not a Laravel project", vim.log.levels.ERROR)
    return
  end
  
  local use_sail = M.has_sail() and not M.prefer_standard_php(laravel_root)
  
  local cmd = use_sail 
    and ("./vendor/bin/sail artisan " .. command)
    or ("php artisan " .. command)
  
  vim.notify("Would run command: " .. cmd .. " in " .. laravel_root, 
           vim.log.levels.INFO, { title = "Laravel Artisan" })
end

-- Helper function to use Sail or PHP based on availability (minimal implementation)
function M.with_sail_or_php(command)
  local laravel_root = M.find_laravel_root()
  if not laravel_root then
    vim.notify("Not a Laravel project", vim.log.levels.ERROR)
    return
  end
  
  -- Determine whether to use Sail
  local use_sail = M.has_sail() and not M.prefer_standard_php(laravel_root)
  
  -- Build the command
  local cmd
  if use_sail then
    cmd = "./vendor/bin/sail " .. command
  else
    -- Replace 'sail' with 'php' if needed
    if command:match("^artisan ") then
      cmd = "php " .. command
    else
      cmd = command
    end
  end
  
  vim.notify("Would run command: " .. cmd .. " in " .. laravel_root, 
           vim.log.levels.INFO, { title = "Laravel Helper" })
  
  return nil -- For now, just return nil instead of a job ID
end

-- Check if user has declined IDE helper generation
function M.is_ide_helper_generate_declined(laravel_root)
  local prefs = M.read_user_preference(laravel_root)
  if not prefs then
    return false
  end
  
  return prefs["ide_helper_generate"] == "declined"
end

-- Additional configuration specific to the plugin
M.config = {
  auto_detect = true,
  docker_timeout = 360000, -- 6 minutes
  prefer_sail = true,
  commands = {
    "ide-helper:generate",    -- PHPDoc generation for Laravel classes
    "ide-helper:models -N",   -- PHPDoc generation for models (no write)
    "ide-helper:meta",        -- PhpStorm Meta file generation
  }
}

-- Setup function that configures the plugin with user options
function M.setup(config)
  -- Merge user config with defaults
  M.config = vim.tbl_deep_extend("force", M.config, config or {})
  
  -- Initialize the global tables for tracking
  vim.g.laravel_ide_helper_checked = vim.g.laravel_ide_helper_checked or {}
  vim.g.laravel_ide_helper_initialized = vim.g.laravel_ide_helper_initialized or false
  vim.g.laravel_ide_helper_installing = vim.g.laravel_ide_helper_installing or false
  vim.g.laravel_ide_helper_use_sail = vim.g.laravel_ide_helper_use_sail or nil
  vim.g.laravel_ide_helper_asked_about_sail = vim.g.laravel_ide_helper_asked_about_sail or false
  
  -- Create user commands for Laravel IDE Helper
  vim.api.nvim_create_user_command("LaravelGenerateIDEHelper", function()
    M.generate_ide_helper(true)
  end, { desc = "Generate Laravel IDE Helper files" })
  
  -- Create a command to install IDE helper package
  vim.api.nvim_create_user_command("LaravelInstallIDEHelper", function()
    M.install_ide_helper()
  end, { desc = "Install Laravel IDE Helper package" })
  
  -- Create command to toggle debug mode
  vim.api.nvim_create_user_command("LaravelIDEHelperToggleDebug", function()
    M.toggle_debug_mode()
  end, { desc = "Toggle Laravel IDE Helper debug mode" })
end

-- Check a Laravel project for IDE Helper status
function M.check_laravel_project()
  -- Get the Laravel root if it exists
  local laravel_root = M.find_laravel_root()
  if not laravel_root then 
    if M.debug_mode then
      vim.notify("Not a Laravel project, skipping IDE Helper check", vim.log.levels.DEBUG)
    end
    return 
  end
  
  -- Add a second layer of protection against duplicate prompts
  local prompt_lock_file = vim.fn.stdpath("cache") .. "/laravel_ide_helper_prompt.lock"
  
  -- First make sure this isn't a duplicate in the same Neovim instance
  if vim.g.laravel_ide_helper_checked[laravel_root] then 
    if M.debug_mode then
      vim.notify("Already checked Laravel project at: " .. laravel_root, vim.log.levels.DEBUG)
    end
    return 
  end
  
  -- Mark this project as checked to avoid multiple prompts in this session
  vim.g.laravel_ide_helper_checked[laravel_root] = true
  if M.debug_mode then
    vim.notify("Marked Laravel project as checked: " .. laravel_root, vim.log.levels.DEBUG)
  end
  
  -- Only present popup dialogs after Neovim is fully loaded
  if vim.v.vim_did_enter ~= 1 then
    if M.debug_mode then
      vim.notify("Neovim not fully loaded yet, deferring IDE Helper check", vim.log.levels.DEBUG)
    end
    
    vim.schedule(function()
      vim.cmd("doautocmd BufEnter " .. vim.fn.fnameescape(vim.api.nvim_buf_get_name(0)))
    end)
    return
  end
  
  -- Skip if we're already in the middle of installation
  if vim.g.laravel_ide_helper_installing then
    if M.debug_mode then
      vim.notify("Installation already in progress, skipping check", vim.log.levels.DEBUG)
    end
    return
  end
  
  -- Skip if there's already an active prompt
  if vim.fn.filereadable(prompt_lock_file) == 1 then
    if M.debug_mode then
      vim.notify("Prompt already active, skipping", vim.log.levels.DEBUG)
    end
    return
  end
  
  -- Create a lock file to prevent concurrent prompts
  local lock_file_path = prompt_lock_file
  os.execute("touch " .. lock_file_path)
  
  -- Check for IDE Helper in this Laravel project but wait until Vim is fully ready
  vim.defer_fn(function()
    -- Clean up lock file function
    local function cleanup_lock()
      os.remove(lock_file_path)
      if M.debug_mode then
        vim.notify("Removed prompt lock file", vim.log.levels.DEBUG)
      end
    end
    
    -- Set up cleanup on timer
    vim.defer_fn(cleanup_lock, 60000) -- 60 second failsafe timeout
    
    -- First check if this is a production environment
    if M.is_production_environment() then
      -- Just show a warning notification but don't prompt to install
      vim.notify(
        "⚠️ This appears to be a production Laravel environment. ⚠️\n" ..
        "IDE Helper installation has been disabled for safety.\n" ..
        "If this is actually a development environment, check your .env file.",
        vim.log.levels.WARN,
        { 
          title = "Laravel IDE Helper - PRODUCTION ENVIRONMENT DETECTED",
          timeout = 10000  -- 10 seconds
        }
      )
      -- Clean up lock file
      cleanup_lock()
      return -- Don't proceed with auto-prompts in production
    end
    
    -- Check if user has previously declined IDE Helper installation
    if M.is_ide_helper_declined(laravel_root) then
      -- User has previously declined and chosen to remember that decision
      -- Silently respect their choice without bothering them
      cleanup_lock()
      return
    end
    
    if not M.has_ide_helper() then
      -- Ask user if they want to install IDE helper package
      local choice = vim.fn.confirm(
        "Laravel IDE Helper is not installed in " .. vim.fn.fnamemodify(laravel_root, ":~") .. 
        ". Install for better autocompletion?", 
        "&Yes\n&No", 
        1
      )
      
      -- Clean up lock file regardless of choice
      cleanup_lock()
      
      if choice == 1 then
        -- User wants to install, proceed with installation
        -- If it's a Sail project but Sail isn't running, ask what to do
        if M.has_sail() and not M.is_sail_running() then
          -- Setup floating window with title
          M.show_ide_helper_window("Laravel IDE Helper Install")
          
          -- Create a buffer logger
          local log_to_buffer = M.create_buffer_logger()
          
          -- Add initial content
          log_to_buffer({
            "Installing Laravel IDE Helper...",
            "Working directory: " .. laravel_root,
            "-------------------------------------------",
            "",
          })
          
          M.handle_sail_not_running(
            laravel_root,
            "install",
            0, -- Pass placeholder - buffer references not needed with nui.nvim
            function() 
              -- On success with Sail
              M.install_ide_helper_with_command(laravel_root, true, 0)
            end,
            function() 
              -- On standard composer
              M.install_ide_helper_with_command(laravel_root, false, 0)
            end,
            function() 
              -- On cancel
              return
            end
          )
        else
          -- No special handling needed, just install
          M.install_ide_helper()
        end
      else
        -- User declined installation, ask if they want to remember this choice
        M.handle_remember_choice(
          laravel_root,
          "ide_helper_install",
          "declined",
          "Would you like to remember this choice for this Laravel project?\n" ..
          "This will prevent future installation prompts.",
          "Preference saved in .nvim-helper. To enable installation prompts again, edit 'ide_helper_install=declined' to 'prompt'."
        )
      end
    elseif not M.ide_helper_files_exist() then
      -- Check if user has declined file generation before
      if M.read_user_preference(laravel_root) and 
         M.read_user_preference(laravel_root)["ide_helper_generate"] == "declined" then
        -- User previously declined, respect their choice
        cleanup_lock()
        return
      end
      
      -- IDE Helper is installed but files aren't generated
      local choice = vim.fn.confirm(
        "Generate Laravel IDE Helper files for better LSP integration?", 
        "&Yes\n&No", 
        1
      )
      
      -- Clean up lock file regardless of choice
      cleanup_lock()
      
      if choice == 1 then
        -- First, if it's a Sail project but Sail isn't running, ask what to do
        if M.has_sail() and not M.is_sail_running() then
          -- Setup floating window with title
          M.show_ide_helper_window("Laravel IDE Helper Generation")
          
          -- Create a buffer logger
          local log_to_buffer = M.create_buffer_logger()
          
          -- Add initial content
          log_to_buffer({
            "Generating Laravel IDE Helper files...",
            "Working directory: " .. laravel_root,
            "-------------------------------------------",
            "",
          })
          
          M.handle_sail_not_running(
            laravel_root,
            "generate",
            0, -- Pass placeholder - buffer references not needed with nui.nvim
            function() 
              -- On success with Sail
              M.generate_ide_helper(false, true, 0)
            end,
            function() 
              -- On standard PHP
              M.generate_ide_helper(false, false, 0)
            end,
            function() 
              -- On cancel
              return
            end
          )
        else
          -- No special handling needed, just generate
          M.generate_ide_helper(false)
        end
      else
        -- User declined generation, ask if they want to remember this choice
        M.handle_remember_choice(
          laravel_root,
          "ide_helper_generate",
          "declined",
          "Would you like to remember this choice for this Laravel project?\n" ..
          "This will prevent future file generation prompts.",
          "Preference saved in .nvim-helper. To enable generation prompts again, edit 'ide_helper_generate=declined' to 'prompt'."
        )
      end
    end
    
    -- Make sure to clean up the lock file at the end
    cleanup_lock()
  end, 1000) -- Delay to avoid disrupting startup
end

-- Convenience function to run an Artisan command with UI
function M.run_artisan_command(command, options)
  options = options or {}
  local laravel_root = M.find_laravel_root()
  
  if not laravel_root then
    vim.notify("Not in a Laravel project", vim.log.levels.ERROR)
    return
  end
  
  -- If no command was provided, prompt for one
  if not command or command == "" then
    vim.ui.input({
      prompt = "Artisan command: ",
      default = options.default or "route:list",
    }, function(input)
      if input and input ~= "" then
        M.run_artisan_command(input, options)
      end
    end)
    return
  end
  
  -- Determine whether to use Sail
  local use_sail = options.use_sail
  if use_sail == nil then
    use_sail = M.has_sail() and not M.prefer_standard_php(laravel_root)
  end
  
  -- Build the command
  local cmd = use_sail 
    and ("./vendor/bin/sail artisan " .. command)
    or ("php artisan " .. command)
  
  -- Setup floating window with title
  M.show_ide_helper_window("Laravel Artisan: " .. command)
  
  -- Create a buffer logger
  local log_to_buffer = M.create_buffer_logger()
  
  -- Add initial content
  log_to_buffer({
    "Running Artisan command: " .. command,
    "Working directory: " .. laravel_root,
    use_sail and "Using Laravel Sail" or "Using standard PHP",
    "-------------------------------------------",
    "",
  })
  
  -- Run the command
  local job_id = vim.fn.jobstart(cmd, {
    cwd = laravel_root,
    stdout_buffered = false,
    stderr_buffered = false,
    on_stdout = function(_, data)
      if data and #data > 0 then
        log_to_buffer(data)
      end
    end,
    on_stderr = function(_, data)
      if data and #data > 0 then
        log_to_buffer(data)
      end
    end,
    on_exit = function(_, code)
      if code == 0 then
        log_to_buffer({
          "",
          "-------------------------------------------",
          "Command completed successfully",
          "-------------------------------------------",
          ""
        })
        
        if options.on_success then
          options.on_success()
        end
      else
        log_to_buffer({
          "",
          "-------------------------------------------",
          "Command failed with exit code: " .. code,
          "-------------------------------------------",
          ""
        })
        
        if options.on_error then
          options.on_error(code)
        end
      end
    end
  })
  
  if job_id <= 0 then
    log_to_buffer({
      "",
      "-------------------------------------------",
      "Failed to start command",
      "-------------------------------------------",
      ""
    })
    
    vim.notify("Failed to start Artisan command", vim.log.levels.ERROR)
    
    if options.on_error then
      options.on_error(-1)
    end
  end
end

-- Helper function to use Sail or PHP based on availability
function M.with_sail_or_php(command, options)
  options = options or {}
  local laravel_root = M.find_laravel_root()
  
  if not laravel_root then
    vim.notify("Not in a Laravel project", vim.log.levels.ERROR)
    return
  end
  
  -- Determine whether to use Sail
  local use_sail = options.use_sail
  if use_sail == nil then
    use_sail = M.has_sail() and not M.prefer_standard_php(laravel_root)
  end
  
  -- If Sail should be used but isn't running, offer to start it
  if use_sail and not M.is_sail_running() then
    local choice = vim.fn.confirm(
      "Laravel Sail is installed but not running. What would you like to do?",
      "&Start Sail first\n&Use standard PHP\n&Cancel",
      1 -- Default to starting Sail
    )
    
    if choice == 1 then -- Start Sail first
      M.start_sail(
        laravel_root,
        nil,
        function()
          -- On success with Sail started, run the command
          M.with_sail_or_php(command, vim.tbl_extend("force", options, {use_sail = true}))
        end,
        function()
          -- On failure to start Sail, use standard PHP
          M.with_sail_or_php(command, vim.tbl_extend("force", options, {use_sail = false}))
        end
      )
      return
    elseif choice == 2 then -- Use standard PHP
      use_sail = false
    else -- Cancel
      return
    end
  end
  
  -- Build the command
  local cmd
  if use_sail then
    cmd = "./vendor/bin/sail " .. command
  else
    -- Replace 'sail' with 'php' if needed
    if command:match("^artisan ") then
      cmd = "php " .. command
    else
      cmd = command
    end
  end
  
  -- Handle UI setup if requested
  if options.show_ui then
    -- Setup floating window with title
    M.show_ide_helper_window("Laravel Command: " .. command)
    
    -- Create a buffer logger
    local log_to_buffer = M.create_buffer_logger()
    
    -- Add initial content
    log_to_buffer({
      "Running command: " .. command,
      "Working directory: " .. laravel_root,
      use_sail and "Using Laravel Sail" or "Using standard PHP",
      "-------------------------------------------",
      "",
    })
  end
  
  -- Run the command
  local job_id = vim.fn.jobstart(cmd, {
    cwd = laravel_root,
    stdout_buffered = false,
    stderr_buffered = false,
    on_stdout = function(_, data)
      if data and #data > 0 then
        if options.show_ui then
          M.create_buffer_logger()(data)
        end
        
        if options.on_stdout then
          options.on_stdout(data)
        end
      end
    end,
    on_stderr = function(_, data)
      if data and #data > 0 then
        if options.show_ui then
          M.create_buffer_logger()(data)
        end
        
        if options.on_stderr then
          options.on_stderr(data)
        end
      end
    end,
    on_exit = function(_, code)
      if code == 0 then
        if options.show_ui then
          M.create_buffer_logger()({
            "",
            "-------------------------------------------",
            "Command completed successfully",
            "-------------------------------------------",
            ""
          })
        end
        
        if options.on_success then
          options.on_success()
        end
      else
        if options.show_ui then
          M.create_buffer_logger()({
            "",
            "-------------------------------------------",
            "Command failed with exit code: " .. code,
            "-------------------------------------------",
            ""
          })
        end
        
        if options.on_error then
          options.on_error(code)
        end
      end
    end
  })
  
  if job_id <= 0 then
    if options.show_ui then
      M.create_buffer_logger()({
        "",
        "-------------------------------------------",
        "Failed to start command",
        "-------------------------------------------",
        ""
      })
    end
    
    vim.notify("Failed to start command: " .. cmd, vim.log.levels.ERROR)
    
    if options.on_error then
      options.on_error(-1)
    end
  end
  
  return job_id
end

return M