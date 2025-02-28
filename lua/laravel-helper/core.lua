-- Core functionality for Laravel Helper
local M = {}

-- Enable to show detailed Laravel IDE Helper debug output
M.debug_mode = false

-- Import the existing PHP utils code
local php_utils = vim.fn.readfile('/home/gregg/mydotfiles/nvim/.config/nvim/lua/utils/php.lua')
local php_utils_content = table.concat(php_utils, '\n')

-- Evaluate the PHP utils code, with adjustments for the new module
local modified_content = php_utils_content:gsub('local M = {}', 'local M = {}')
                                        :gsub('return M', 'return M')

-- Create a temporary file to load the code
local temp_file = vim.fn.tempname() .. '.lua'
vim.fn.writefile(vim.split(modified_content, '\n'), temp_file)

-- Load the module
local core = dofile(temp_file)

-- Clean up temporary file
vim.fn.delete(temp_file)

-- Copy all functions from the loaded module to our module
for k, v in pairs(core) do
  M[k] = v
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