local M = {}

-- Enable to show detailed Laravel IDE Helper debug output
M.debug_mode = false

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

-- Detect if the current project is a Laravel project
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

-- Check if the IDE Helper has been explicitly declined
function M.is_ide_helper_declined(laravel_root)
  local prefs = M.read_user_preference(laravel_root)
  if not prefs then
    return false
  end
  
  return prefs["ide_helper_install"] == "declined"
end

-- Handle "remember this choice" prompt and save user preference
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

-- Check if the Laravel project is in production environment
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

-- Detect if Laravel IDE Helper is installed
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

-- Check if Sail is running by checking Docker containers
function M.is_sail_running()
  local laravel_root = M.find_laravel_root()
  if not laravel_root or not M.has_sail() then
    return false
  end
  
  -- A more reliable way to check if Sail is running by checking Docker containers
  local cmd = "docker ps --format '{{.Names}}' | grep -q 'laravel\\.test\\|sail'"
  local exit_code = os.execute(cmd)
  
  -- os.execute returns true (and exit code 0) if the command succeeds
  return exit_code == 0 or exit_code == true
end

-- Common Sail command functions to prevent duplication
function M.get_sail_up_cmd()
  return "./vendor/bin/sail up --remove-orphans -d"
end

function M.get_sail_down_cmd()
  return "./vendor/bin/sail down"
end

function M.get_sail_install_cmd(options)
  return "php artisan sail:install" .. (options and (" --with=" .. options) or "")
end

function M.get_full_command(cmd, cwd)
  return "cd " .. vim.fn.shellescape(cwd) .. " && " .. cmd
end

-- Run a command asynchronously with buffer output support
function M.run_job(cmd, cwd, buffer, on_success, on_failure, options)
  options = options or {}
  local log_to_buffer = M.create_buffer_logger(buffer)
  local timeout = options.timeout or 360000 -- Default 6 minute timeout for Docker operations
  local completion_message = options.completion_message or "Command completed successfully"
  local success_prefix = options.success_prefix or ""
  local error_prefix = options.error_prefix or ""
  
  -- Add command information to the buffer, but skip for certain commands
  if cmd:match("echo.*Waiting for database") then
    -- For wait commands, only show the message without command details
    log_to_buffer({
      "",
      "Waiting for database to initialize...",
      "-------------------------------------------",
      ""
    })
  else
    -- For other commands, show the full details
    log_to_buffer({
      "",
      "Running command: " .. cmd,
      "Working directory: " .. cwd,
      "-------------------------------------------",
      "",
    })
  end
  
  -- Handle special error detection for Sail/Docker and Laravel
  local detect_sail_errors = options.detect_sail_errors or false
  local detect_laravel_errors = options.detect_laravel_errors or false
  local sail_error_detected = false
  local docker_error_detected = false
  local db_connection_error = false
  local model_not_found_error = false
  
  -- Keep track of command success/failure
  local job_success = false
  local job_complete = false
  
  -- Start the command
  local job_id = vim.fn.jobstart(cmd, {
    cwd = cwd,
    stdout_buffered = false,
    stderr_buffered = false,
    on_stdout = function(_, data)
      if data and #data > 0 then
        -- Try to detect sail-specific errors in the output if requested
        if detect_sail_errors then
          for _, line in ipairs(data) do
            if type(line) == "string" then
              if line:match("Docker.* not running") or line:match("Cannot connect to the Docker daemon") then
                docker_error_detected = true
              elseif line:match("Error response from daemon") or line:match("Sail is not running") then
                sail_error_detected = true
              end
            end
          end
        end
        
        -- Detect Laravel-specific errors if requested
        if detect_laravel_errors then
          for _, line in ipairs(data) do
            if type(line) == "string" then
              if line:match("could not find driver") or 
                 line:match("database.+connection") or
                 line:match("SQLSTATE") then
                db_connection_error = true
              elseif line:match("Model.+not found") or 
                     line:match("Class.+not found") or
                     line:match("table.+does not exist") then
                model_not_found_error = true
              end
            end
          end
        end
        
        -- Log all stdout to buffer
        log_to_buffer(data)
      end
    end,
    on_stderr = function(_, data)
      if data and #data > 0 then
        -- Try to detect sail-specific errors in stderr if requested
        if detect_sail_errors then
          for _, line in ipairs(data) do
            if type(line) == "string" then
              if line:match("Docker.* not running") or line:match("Cannot connect to the Docker daemon") then
                docker_error_detected = true
              elseif line:match("Error response from daemon") or line:match("Sail is not running") then
                sail_error_detected = true
              end
            end
          end
        end
        
        -- Detect Laravel-specific errors if requested (stderr often has the more detailed errors)
        if detect_laravel_errors then
          for _, line in ipairs(data) do
            if type(line) == "string" then
              if line:match("could not find driver") or 
                 line:match("database.+connection") or
                 line:match("SQLSTATE") then
                db_connection_error = true
              elseif line:match("Model.+not found") or 
                     line:match("Class.+not found") or
                     line:match("table.+does not exist") or
                     line:match("ReflectionException") then
                model_not_found_error = true
              end
            end
          end
        end
        
        -- Log stderr to buffer
        log_to_buffer(data)
      end
    end,
    on_exit = function(_, code)
      if code == 0 then
        job_success = true
        log_to_buffer({
          "",
          "-------------------------------------------",
          success_prefix .. completion_message,
          "-------------------------------------------",
          ""
        })
        
        job_complete = true
        
        -- Call success callback after a brief delay
        if on_success then
          vim.defer_fn(function()
            on_success({
              sail_error_detected = sail_error_detected,
              docker_error_detected = docker_error_detected
            })
          end, 100)
        end
      else
        job_success = false
        
        -- Prepare error message based on detected errors
        local error_msg = {
          "",
          "-------------------------------------------",
          error_prefix .. "Command failed with exit code: " .. code,
          "",
        }
        
        -- Add specific error information if available
        if detect_sail_errors then
          if docker_error_detected then
            table.insert(error_msg, "Docker does not appear to be running or accessible.")
            table.insert(error_msg, "Possible next steps:")
            table.insert(error_msg, "1. Start Docker Desktop or the Docker daemon")
            table.insert(error_msg, "2. Make sure the current user has permissions to access Docker")
          elseif sail_error_detected then
            table.insert(error_msg, "Sail environment appears to have issues.")
            table.insert(error_msg, "Possible next steps:")
            table.insert(error_msg, "1. Try starting Sail manually: " .. M.get_sail_up_cmd())
            table.insert(error_msg, "2. Check docker-compose.yml for configuration errors")
            table.insert(error_msg, "3. Ensure no conflicting services are using the same ports")
          end
        end
        
        table.insert(error_msg, "-------------------------------------------")
        table.insert(error_msg, "")
        
        log_to_buffer(error_msg)
        
        job_complete = true
        
        -- Call failure callback after a brief delay
        if on_failure then
          vim.defer_fn(function()
            on_failure({
              exit_code = code,
              sail_error_detected = sail_error_detected,
              docker_error_detected = docker_error_detected
            })
          end, 100)
        end
      end
    end
  })
  
  if job_id <= 0 then
    log_to_buffer({
      "",
      "-------------------------------------------",
      "Failed to start command",
      "Command: " .. cmd,
      "-------------------------------------------",
      ""
    })
    
    job_complete = true
    job_success = false
    
    -- Call failure callback after a brief delay
    if on_failure then
      vim.defer_fn(function()
        on_failure({
          exit_code = -1,
          job_start_failed = true
        })
      end, 100)
    end
    
    return false
  end
  
  -- For synchronous execution, wait for completion if requested
  if options.wait then
    -- Wait for job to complete with timeout
    local wait_result = vim.wait(timeout, function() return job_complete end, 100)
    
    if not wait_result then
      log_to_buffer({
        "",
        "-------------------------------------------",
        "Command timed out after " .. (timeout / 1000) .. " seconds",
        "The operation may still be running in the background",
        "-------------------------------------------",
        ""
      })
      
      if on_failure then
        on_failure({
          exit_code = -2,
          timed_out = true
        })
      end
      
      return false
    end
    
    return job_success
  end
  
  return true -- Job started successfully
end

-- Check if user has specified to always use standard PHP instead of Sail
function M.prefer_standard_php(laravel_root)
  local prefs = M.read_user_preference(laravel_root)
  if not prefs then
    return false
  end
  
  return prefs["use_standard_php"] == "always"
end

-- Check if Docker is installed and running
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

-- Check if Docker Compose file exists for Sail
function M.has_docker_compose()
  local laravel_root = M.find_laravel_root()
  if not laravel_root then
    return false
  end
  
  -- Check for both the newer and older Docker Compose file formats
  local has_yml = vim.fn.filereadable(laravel_root .. "/docker-compose.yml") == 1
  local has_yaml = vim.fn.filereadable(laravel_root .. "/docker-compose.yaml") == 1
  
  -- Debug output only if debug mode is enabled
  if M.debug_mode then
    vim.notify("Checking for docker-compose files: has_yml=" .. tostring(has_yml) ..
              ", has_yaml=" .. tostring(has_yaml) .. ", path=" .. laravel_root,
              vim.log.levels.DEBUG, { title = "Laravel IDE Helper" })
  end
  
  return has_yml or has_yaml
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

-- State tracking for database connection status
M.last_db_connection_failed = false

-- Setup nui.nvim popup
M.ide_helper_window = {
  popup = nil,
  buffer = nil,
  lines = {},
  mounted = false,
  logger = function(message) 
    -- Default logger if NUI isn't available
    if type(message) == "table" then
      vim.notify(table.concat(message, "\n"))
    elseif type(message) == "string" then
      vim.notify(message)
    end
  end
}

-- Creates and shows a floating window for Laravel IDE Helper output
function M.show_ide_helper_window(title)
  title = title or "Laravel IDE Helper"
  
  -- Try to load nui.nvim
  local ok, Popup = pcall(require, "nui.popup")
  if not ok then
    vim.notify("nui.nvim not found. Using default notifications.", vim.log.levels.WARN)
    vim.notify("Laravel IDE Helper: " .. title, vim.log.levels.INFO)
    return M.ide_helper_window
  end
  
  -- Close existing popup if it exists
  if M.ide_helper_window.popup and M.ide_helper_window.mounted then
    pcall(function() M.ide_helper_window.popup:unmount() end)
    M.ide_helper_window.mounted = false
  end
  
  -- Create a new popup
  M.ide_helper_window.popup = Popup({
    enter = true,
    focusable = true,
    border = {
      style = "rounded",
      text = {
        top = " " .. title .. " ",
        top_align = "center",
      },
    },
    position = "50%",
    size = {
      width = math.min(85, vim.o.columns - 10),
      height = math.min(25, vim.o.lines - 10),
    },
    buf_options = {
      modifiable = true,
      readonly = false,
      filetype = "log",
    },
    win_options = {
      wrap = true,
      foldenable = false,
      cursorline = true,
    },
  })
  
  -- Set keymaps to close the popup
  M.ide_helper_window.popup:map("n", "q", function()
    pcall(function() M.ide_helper_window.popup:unmount() end)
    M.ide_helper_window.mounted = false
  end, { noremap = true })
  
  M.ide_helper_window.popup:map("n", "<Esc>", function()
    pcall(function() M.ide_helper_window.popup:unmount() end)
    M.ide_helper_window.mounted = false
  end, { noremap = true })
  
  -- Use mounted event handler
  M.ide_helper_window.popup:on(require("nui.utils.autocmd").event.BufWinEnter, function()
    M.ide_helper_window.mounted = true
    
    -- Set initial content if we have any
    if #M.ide_helper_window.lines > 0 then
      vim.api.nvim_buf_set_lines(
        M.ide_helper_window.popup.bufnr, 
        0, -1, false, 
        M.ide_helper_window.lines
      )
      
      -- Auto-scroll to bottom
      vim.schedule(function()
        if M.ide_helper_window.mounted then
          local line_count = vim.api.nvim_buf_line_count(M.ide_helper_window.popup.bufnr)
          pcall(vim.api.nvim_win_set_cursor, M.ide_helper_window.popup.winid, {line_count, 0})
        end
      end)
    end
  end)
  
  -- Mount the popup
  M.ide_helper_window.popup:mount()
  
  return M.ide_helper_window
end

-- Create a unified buffer logger function
function M.create_buffer_logger(buffer)
  -- Ignore the buffer parameter - we'll use the nui popup exclusively
  
  -- Return a function that logs to the popup
  return function(message)
    if not message or (type(message) == "string" and message == "") or 
       (type(message) == "table" and #message == 0) then 
      return 
    end
    
    local filtered_lines = {}
    
    if type(message) == "table" then
      -- Handle table of lines
      for _, line in ipairs(message) do
        if line and line ~= "" then
          -- Split each line in case it contains newlines
          if type(line) == "string" and line:find("\n") then
            for subline in line:gmatch("[^\r\n]+") do
              -- Strip ANSI color codes
              subline = subline:gsub("\27%[[0-9;:]*m", "")
              table.insert(filtered_lines, subline)
            end
          else
            if type(line) == "string" then
              -- Strip ANSI color codes
              line = line:gsub("\27%[[0-9;:]*m", "")
            end
            table.insert(filtered_lines, line)
          end
        end
      end
    else
      -- Handle string, possibly with newlines
      if message:find("\n") then
        for line in message:gmatch("[^\r\n]+") do
          -- Strip ANSI color codes
          line = line:gsub("\27%[[0-9;:]*m", "")
          table.insert(filtered_lines, line)
        end
      else
        -- Strip ANSI color codes
        message = message:gsub("\27%[[0-9;:]*m", "")
        table.insert(filtered_lines, message)
      end
    end
    
    -- Only proceed if we have valid lines to add
    if #filtered_lines == 0 then return end
    
    -- Add lines to our saved lines (to restore if popup is recreated)
    for _, line in ipairs(filtered_lines) do
      table.insert(M.ide_helper_window.lines, line)
    end
    
    -- If popup is mounted, append lines to it
    vim.schedule(function()
      if M.ide_helper_window.mounted and M.ide_helper_window.popup then
        -- Safe access to bufnr
        local bufnr = M.ide_helper_window.popup.bufnr
        if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
          -- Safe line count retrieval
          local ok, line_count = pcall(vim.api.nvim_buf_line_count, bufnr)
          if ok then
            pcall(vim.api.nvim_buf_set_lines, bufnr, line_count, line_count, false, filtered_lines)
            
            -- Auto-scroll to bottom
            local ok2, _ = pcall(vim.api.nvim_win_set_cursor, M.ide_helper_window.popup.winid, {line_count + #filtered_lines, 0})
            if not ok2 then
              -- Try once more
              vim.defer_fn(function()
                if M.ide_helper_window.mounted then
                  pcall(vim.api.nvim_win_set_cursor, M.ide_helper_window.popup.winid, {line_count + #filtered_lines, 0})
                end
              end, 10)
            end
          end
        else
          -- If buffer is not valid, recreate the popup
          M.show_ide_helper_window()
        end
      else
        -- If not mounted, create and mount the popup
        M.show_ide_helper_window()
      end
    end)
    
    return M.ide_helper_window.popup and M.ide_helper_window.popup.bufnr
  end
end

-- Toggle debug mode for Laravel IDE Helper
function M.toggle_debug_mode()
  M.debug_mode = not M.debug_mode
  vim.notify("Laravel IDE Helper debug mode: " .. (M.debug_mode and "ENABLED" or "DISABLED"), 
            vim.log.levels.INFO, { title = "Laravel IDE Helper" })
  
  if M.debug_mode then
    vim.notify("Debug mode will show detailed notifications about Laravel IDE Helper operations.", 
              vim.log.levels.INFO, { title = "Laravel IDE Helper" })
  end
  
  return M.debug_mode
end

-- Helper function to execute commands for IDE Helper
function M.execute_commands_for_ide_helper(commands, laravel_root, log_to_buffer)
  -- Track success of all commands
  local all_succeeded = true
  
  -- Run commands sequentially in background
  local run_next_command
  local command_index = 1
  
  -- Variables to allow conditional execution
  local skip_migration_index = nil
  local db_connection_check_index = nil
  
  -- Reset database connection state for this run
  M.last_db_connection_failed = false
  
  -- Find the indexes of DB connection check and migration commands
  for i, cmd in ipairs(commands) do
    if cmd:match("artisan tinker.*DB::connection") then
      db_connection_check_index = i
    elseif cmd:match("artisan migrate") and db_connection_check_index then
      -- This is a migration command that follows a DB check
      skip_migration_index = i
      break
    end
  end
  
  -- Let's create a modified command list that dynamically skips migrations
  -- based on previous DB connection results
  local function get_next_command()
    if command_index > #commands then
      return nil
    end
    
    local cmd = commands[command_index]
    command_index = command_index + 1
    
    -- If this is a migration command and previous DB connection failed,
    -- skip it and get the next command
    if cmd:match("artisan migrate") and M.last_db_connection_failed then
      log_to_buffer({
        "",
        "Skipping database migration due to previous connection failure.",
        ""
      })
      return get_next_command() -- Recursively get the next valid command
    end
    
    return cmd
  end
  
  run_next_command = function()
    local cmd = get_next_command()
    
    if not cmd then
      -- All commands complete
      if all_succeeded then
        log_to_buffer({
          "",
          "-------------------------------------------",
          "All Laravel IDE Helper files generated successfully!",
          "Restarting PHP LSP server..."
        })
        
        -- Final success notification is still useful
        vim.notify("Laravel IDE Helper files generated successfully", 
                 vim.log.levels.INFO, { title = "Laravel IDE Helper" })
        
        -- Reload LSP for the current buffer to pick up the new definitions
        vim.schedule(function()
          -- Restart all active LSP servers without specifying a particular one
          vim.cmd("LspRestart")
          log_to_buffer("LSP server restart initiated")
          
          -- Give it a moment to restart, then reload the current buffer
          vim.defer_fn(function()
            -- Force reload of the current buffer
            local current_buf = vim.api.nvim_get_current_buf()
            local current_file = vim.api.nvim_buf_get_name(current_buf)
            
            if current_file ~= "" then
              -- Add success message to buffer but don't send an extra notification
              log_to_buffer({
                "",
                "-------------------------------------------",
                "IDE Helper process completed successfully!",
                "All files have been generated and the LSP server has been restarted.",
                "You may now close this buffer manually when you're done reviewing the output.",
                "-------------------------------------------",
                ""
              })
            end
          end, 2000) -- 2 second delay to allow LSP to restart fully
        end)
      else
        log_to_buffer({
          "",
          "-------------------------------------------",
          "Some IDE Helper commands failed. Check the logs above for details.",
          "You may need to run the commands manually in your Laravel project directory."
        })
        
        vim.notify("Some Laravel IDE Helper commands failed. See buffer for details.", 
                  vim.log.levels.WARN, { title = "Laravel IDE Helper" })
      end
      
      -- Clean up global state when finished
      vim.g.laravel_ide_helper_installing = false
      vim.g.laravel_ide_helper_use_sail = nil
      
      return
    end
    
    log_to_buffer({
      "",
      "Running: " .. cmd
    })
    
    local job_id = vim.fn.jobstart(cmd, {
      cwd = laravel_root,
      stdout_buffered = false,
      stderr_buffered = false,
      on_stdout = function(_, data)
        if data and #data > 0 then
          -- Check for Laravel-specific errors in the output
          for _, line in ipairs(data) do
            if type(line) == "string" then
              if line:match("could not find driver") or 
                line:match("database.+connection") or
                line:match("SQLSTATE") then
                -- Detected database connection issue
                M.last_db_connection_failed = true
                log_to_buffer({
                  "DATABASE CONNECTION ERROR DETECTED: This might be because the database is not ready or properly configured.",
                  "Consider running 'php artisan migrate' manually if this is a fresh Laravel project.",
                })
              elseif line:match("Model.+not found") or 
                    line:match("Class.+not found") or
                    line:match("table.+does not exist") then
                -- Detected schema/model issue
                log_to_buffer({
                  "MODEL/SCHEMA ERROR DETECTED: This might be because database tables are not properly set up.",
                  "The IDE helper might still generate partial information despite this error.",
                })
              end
            end
          end
          
          -- Only log to buffer, no notifications
          log_to_buffer(data)
        end
      end,
      on_stderr = function(_, data)
        if data and #data > 0 then
          log_to_buffer(data)
        end
      end,
      on_exit = function(_, code)
        -- Check if this is a DB-related command which can fail but we should continue
        local is_db_command = cmd:match("artisan migrate") or 
                             cmd:match("artisan db:seed") or
                             cmd:match("artisan tinker") or
                             cmd:match("sleep [0-9]+")
        
        if code ~= 0 then
          -- Only mark as failure if it's not a database command
          if not is_db_command then
            all_succeeded = false
          end
          
          if is_db_command then
            if cmd:match("artisan tinker") and cmd:match("DB::connection") then
              -- Record that DB connection failed for later commands
              M.last_db_connection_failed = true
              
              log_to_buffer({
                "Database connection failed. Database may still be initializing or credentials may be incorrect.",
                "Will skip migration and continue with IDE Helper generation.",
                "Some model information may be incomplete without database connection.",
                "-------------------------------------------"
              })
            elseif cmd:match("artisan migrate") then
              -- Record that database setup failed
              M.last_db_connection_failed = true
              
              log_to_buffer({
                "Database migration failed with code: " .. code,
                "This is non-critical, continuing with IDE Helper generation...",
                "Note: Some IDE helper model information may be incomplete without migrated tables.",
                "-------------------------------------------"
              })
            else
              log_to_buffer({
                "Database command exited with code: " .. code,
                "This is non-critical, continuing with IDE Helper generation...",
                "-------------------------------------------"
              })
            end
          else
            log_to_buffer({
              "Command failed with exit code: " .. code,
              "-------------------------------------------"
            })
          end
        else
          -- Show success message, with special handling for IDE Helper model generation
          if cmd:match("ide%-helper:models") and M.last_db_connection_failed then
            -- If we had a previous DB connection failure, the models command may not have worked fully
            log_to_buffer({
              "Command completed, but database connection issues may have limited the results.",
              "-------------------------------------------"
            })
          else
            log_to_buffer({
              "Command completed successfully",
              "-------------------------------------------"
            })
          end
        end
        
        -- Move to next command
        run_next_command()
      end
    })
    
    if job_id <= 0 then
      log_to_buffer("Failed to start command: " .. cmd)
      all_succeeded = false
      run_next_command()
    end
  end
  
  -- Start the command chain
  run_next_command()
end

-- Install Laravel IDE Helper
function M.install_ide_helper()
  if M.debug_mode then
    vim.notify("Starting IDE Helper installation", vim.log.levels.DEBUG)
  end
  
  -- Set installing flag to prevent duplicate prompts
  vim.g.laravel_ide_helper_installing = true
  
  local laravel_root = M.find_laravel_root()
  if not laravel_root then
    vim.notify("Not a Laravel project", vim.log.levels.WARN)
    vim.g.laravel_ide_helper_installing = false
    return false
  end
  
  -- Make sure this project is marked as checked to avoid prompting again
  if not vim.g.laravel_ide_helper_checked then
    vim.g.laravel_ide_helper_checked = {}
  end
  vim.g.laravel_ide_helper_checked[laravel_root] = true
  if M.debug_mode then
    vim.notify("Marking Laravel project as checked during install: " .. laravel_root, vim.log.levels.DEBUG)
  end
  
  -- Check if this is a production environment and warn the user
  if M.is_production_environment() then
    vim.notify(
      "⚠️ WARNING: This appears to be a production Laravel environment. ⚠️\n" ..
      "Installing IDE Helper in production is not recommended.\n" ..
      "Please check your .env file or config/app.php.",
      vim.log.levels.ERROR,
      { 
        title = "Laravel IDE Helper - PRODUCTION ENVIRONMENT DETECTED",
        timeout = 10000  -- 10 seconds (twice the default 5000ms)
      }
    )
    
    -- Ask for confirmation before proceeding
    local choice = vim.fn.confirm(
      "This appears to be a production Laravel environment. IDE Helper should NOT be used in production.\n" ..
      "Are you absolutely sure you want to continue?",
      "&Cancel\n&I understand the risks, proceed anyway",
      1 -- Default to Cancel
    )
    
    if choice ~= 2 then -- Not confirmed
      vim.notify("Laravel IDE Helper installation cancelled", vim.log.levels.INFO)
      return false
    end
    
    -- If they confirm, show one more strong warning
    vim.notify(
      "⚠️ Proceeding with IDE Helper in PRODUCTION environment at user's request! ⚠️\n" ..
      "This is NOT recommended and could potentially modify production data.",
      vim.log.levels.WARN,
      { 
        title = "Laravel IDE Helper - PROCEEDING IN PRODUCTION", 
        timeout = 10000  -- 10 seconds (twice the default 5000ms)
      }
    )
  end
  
  -- Check user preference for standard PHP first
  if M.prefer_standard_php(laravel_root) then
    vim.notify("Using standard PHP/composer (as per saved preference).", 
              vim.log.levels.INFO, { title = "Laravel IDE Helper" })
    
    -- Set up the floating window first
    M.show_ide_helper_window("Laravel IDE Helper Install")
    
    -- Now call the command function with a dummy buffer
    return M.install_ide_helper_with_command(laravel_root, false, 0)
  end
  
  local use_sail = M.has_sail()
  local is_docker_available = M.is_docker_available()
  
  -- If Sail is available but Docker isn't, we should fall back to standard composer
  if use_sail and not is_docker_available then
    vim.notify("Laravel Sail is available, but Docker is not installed or not running. Using standard composer.", 
              vim.log.levels.WARN, { title = "Laravel IDE Helper" })
    use_sail = false
  end
  
  local sail_running = use_sail and M.is_sail_running()
  local has_docker_compose = use_sail and M.has_docker_compose()
  
  -- Debug output only if debug mode is enabled
  if M.debug_mode then
    vim.notify("Checking docker-compose - use_sail=" .. tostring(use_sail) .. 
              ", has_docker_compose=" .. tostring(has_docker_compose) ..
              ", global preference=" .. tostring(vim.g.laravel_ide_helper_use_sail) ..
              ", asked flag=" .. tostring(vim.g.laravel_ide_helper_asked_about_sail),
              vim.log.levels.DEBUG, { title = "Laravel IDE Helper" })
  end
  
  -- Set up the window for installation output
  M.show_ide_helper_window("Laravel IDE Helper Installation")
  
  -- Use local command or sail based on availability and preferences
  use_sail = use_sail and not M.prefer_standard_php(laravel_root)
  
  local cmd
  if use_sail then
    cmd = "cd " .. vim.fn.shellescape(laravel_root) .. " && ./vendor/bin/sail composer require --dev barryvdh/laravel-ide-helper"
  else
    cmd = "cd " .. vim.fn.shellescape(laravel_root) .. " && composer require --dev barryvdh/laravel-ide-helper"
  end
  
  -- Create a buffer logger
  local log_to_buffer = M.create_buffer_logger()
  
  -- Add initial content
  log_to_buffer({
    "Installing Laravel IDE Helper...",
    "Working directory: " .. laravel_root,
    use_sail and "Using Laravel Sail" or "Using standard PHP",
    "-------------------------------------------",
    "",
    "Running: " .. cmd
  })
  
  -- Run the command to install IDE Helper
  local job_id = vim.fn.jobstart(cmd, {
    on_stdout = function(_, data)
      if data then
        log_to_buffer(data)
      end
    end,
    on_stderr = function(_, data)
      if data then
        log_to_buffer(data)
      end
    end,
    on_exit = function(_, code)
      if code == 0 then
        log_to_buffer({
          "",
          "-------------------------------------------",
          "Laravel IDE Helper installed successfully!",
          "-------------------------------------------",
          ""
        })
        
        vim.notify("Laravel IDE Helper installed successfully!", vim.log.levels.INFO, 
                 { title = "Laravel IDE Helper" })
        
        -- Ask if they want to generate IDE helper files now
        vim.schedule(function()
          local generate_now = vim.fn.confirm(
            "Laravel IDE Helper installed successfully! Generate helper files now?",
            "&Yes\n&No",
            1
          )
          
          if generate_now == 1 then
            -- We're still in the installation process while generating files
            vim.g.laravel_ide_helper_installing = true
            
            -- Save the user's choice about Sail vs standard PHP in a global variable
            vim.g.laravel_ide_helper_use_sail = use_sail
            
            -- IMPORTANT: Set a flag to indicate we've already asked about Sail vs PHP preferences
            -- This will prevent the generate function from asking again
            vim.g.laravel_ide_helper_asked_about_sail = true
            
            if M.debug_mode then
              vim.notify("DEBUG: Preserving Sail preference: " .. tostring(use_sail), 
                        vim.log.levels.DEBUG, { title = "Laravel IDE Helper" })
            end
            
            M.generate_ide_helper(true)
          end
        end)
      else
        log_to_buffer({
          "",
          "-------------------------------------------",
          "INSTALLATION FAILED with exit code: " .. code,
          "-------------------------------------------",
          ""
        })
        
        vim.notify("Failed to install Laravel IDE Helper (exit code: " .. code .. ")",
                 vim.log.levels.ERROR, { title = "Laravel IDE Helper" })
        
        -- Clear the installing flag since we're done (with failure)
        vim.g.laravel_ide_helper_installing = false
      end
    end
  })
  
  if job_id <= 0 then
    log_to_buffer({
      "",
      "-------------------------------------------",
      "Failed to start installation command",
      "-------------------------------------------",
      ""
    })
    
    vim.notify("Failed to start installation command", vim.log.levels.ERROR)
    return false
  end
  
  return true
end

-- Generate IDE Helper files
function M.generate_ide_helper(force)
  if M.debug_mode then
    vim.notify("Starting IDE Helper generation", vim.log.levels.DEBUG)
  end
  
  local laravel_root = M.find_laravel_root()
  if not laravel_root then
    vim.notify("Not a Laravel project", vim.log.levels.WARN)
    return false
  end
  
  -- Reset database connection state for this run
  M.last_db_connection_failed = false
  
  -- Mark this project as checked to avoid multiple prompts in this session 
  -- (do this for generation too, not just installation)
  if not vim.g.laravel_ide_helper_checked then
    vim.g.laravel_ide_helper_checked = {}
  end
  vim.g.laravel_ide_helper_checked[laravel_root] = true
  if M.debug_mode then
    vim.notify("Marking Laravel project as checked during generation: " .. laravel_root, vim.log.levels.DEBUG)
  end
  
  -- Check if this is a production environment and warn the user
  if M.is_production_environment() then
    vim.notify(
      "⚠️ WARNING: This appears to be a production Laravel environment. ⚠️\n" ..
      "Generating IDE Helper files in production is not recommended.\n" ..
      "Please check your .env file or config/app.php.",
      vim.log.levels.ERROR,
      { 
        title = "Laravel IDE Helper - PRODUCTION ENVIRONMENT DETECTED",
        timeout = 10000  -- 10 seconds (twice the default 5000ms)
      }
    )
    
    -- Ask for confirmation before proceeding
    local choice = vim.fn.confirm(
      "This appears to be a production Laravel environment. IDE Helper should NOT be used in production.\n" ..
      "Are you absolutely sure you want to continue?",
      "&Cancel\n&I understand the risks, proceed anyway",
      1 -- Default to Cancel
    )
    
    if choice ~= 2 then -- Not confirmed
      vim.notify("Laravel IDE Helper generation cancelled", vim.log.levels.INFO)
      return false
    end
    
    -- If they confirm, show one more strong warning
    vim.notify(
      "⚠️ Proceeding with IDE Helper in PRODUCTION environment at user's request! ⚠️\n" ..
      "This is NOT recommended and could potentially modify production data.",
      vim.log.levels.WARN,
      { 
        title = "Laravel IDE Helper - PROCEEDING IN PRODUCTION", 
        timeout = 10000  -- 10 seconds (twice the default 5000ms)
      }
    )
  end
  
  if not force and M.ide_helper_files_exist() then
    vim.notify("IDE Helper files already exist. Use force=true to regenerate.", 
             vim.log.levels.INFO, { title = "Laravel IDE Helper" })
    return true
  end
  
  if not M.has_ide_helper() then
    vim.notify("Laravel IDE Helper is not installed. Please install it first.", 
             vim.log.levels.INFO, { title = "Laravel IDE Helper" })
    
    -- Ask if they want to install it
    vim.schedule(function()
      local install_now = vim.fn.confirm(
        "Laravel IDE Helper is not installed. Would you like to install it now?",
        "&Yes\n&No",
        1
      )
      
      if install_now == 1 then
        M.install_ide_helper()
      end
    end)
    
    return false
  end
  
  -- Set up the window for generation output
  M.show_ide_helper_window("Laravel IDE Helper Generation")
  
  -- Use local command or sail based on availability and preferences
  local use_sail = M.has_sail() and not M.prefer_standard_php(laravel_root)
  
  -- Commands to run
  local commands = {}
  
  -- First migrate the database to ensure schema is ready 
  -- (important for IDE helper which relies on the database schema)
  if use_sail then
    -- Wait for the database to be ready - customized message is handled by run_job
    table.insert(commands, "echo 'Waiting for database to initialize...' && sleep 5")
    
    -- Create a database connection test with a command that works in all Laravel versions
    table.insert(commands, "./vendor/bin/sail php artisan tinker --execute=\"try { DB::connection()->getPdo(); echo 'Database connection successful.'; } catch (\\\\Exception \\$e) { echo 'Database connection failed: ' . \\$e->getMessage(); exit(1); }\"")
    
    -- Then include migration command with reduced verbosity
    table.insert(commands, "./vendor/bin/sail php artisan migrate --quiet") -- Run migrations with minimal output
    
    -- Add IDE helper commands with Sail prefix
    table.insert(commands, "./vendor/bin/sail php artisan ide-helper:generate --quiet") -- Generates basic PHPDoc with minimal output
    table.insert(commands, "./vendor/bin/sail php artisan ide-helper:models -N --quiet") -- Generates PHPDocs for models with minimal output
    table.insert(commands, "./vendor/bin/sail php artisan ide-helper:meta --quiet")  -- Generates PhpStorm meta file with minimal output
  else
    -- Not using Sail, use standard PHP versions
    
    -- Add database connection check and migration for standard PHP
    table.insert(commands, "php artisan tinker --execute=\"try { DB::connection()->getPdo(); echo 'Database connection successful.'; } catch (\\\\Exception \\$e) { echo 'Database connection failed: ' . \\$e->getMessage(); exit(1); }\"")
    table.insert(commands, "php artisan migrate --quiet") -- Add migration after connection check with minimal output
    
    -- Add standard PHP IDE helper commands
    table.insert(commands, "php artisan ide-helper:generate --quiet") -- Generates basic PHPDoc with minimal output
    table.insert(commands, "php artisan ide-helper:models -N --quiet") -- Generates PHPDocs for models with minimal output
    table.insert(commands, "php artisan ide-helper:meta --quiet")  -- Generates PhpStorm meta file with minimal output
  end
  
  -- Construct full commands with proper cwd
  for i, cmd in ipairs(commands) do
    commands[i] = "cd " .. vim.fn.shellescape(laravel_root) .. " && " .. cmd
  end
  
  -- Create a buffer logger
  local log_to_buffer = M.create_buffer_logger()
  
  -- Add initial content
  log_to_buffer({
    "Generating Laravel IDE Helper files...",
    "Working directory: " .. laravel_root,
    "Using " .. (use_sail and "Laravel Sail" or "standard PHP"),
    "-------------------------------------------",
    "",
  })
  
  -- Only one notification at the beginning
  vim.notify("Generating Laravel IDE Helper files. See buffer for progress.", 
            vim.log.levels.INFO, { title = "Laravel IDE Helper" })
  
  -- Execute commands
  M.execute_commands_for_ide_helper(commands, laravel_root, log_to_buffer)
  
  return true
end

-- Helper function to install with specific command type
function M.install_ide_helper_with_command(laravel_root, use_sail, existing_bufnr)
  -- Log debug information
  if M.debug_mode then
    vim.notify("install_ide_helper_with_command called with use_sail=" .. tostring(use_sail) .. 
              ", global pref=" .. tostring(vim.g.laravel_ide_helper_use_sail),
              vim.log.levels.DEBUG, { title = "Laravel IDE Helper" })
  end
  
  local cmd = use_sail
    and "./vendor/bin/sail composer require --dev barryvdh/laravel-ide-helper"
    or "composer require --dev barryvdh/laravel-ide-helper"
  
  -- Check if Sail is accessible if we're supposed to use it
  if use_sail and vim.fn.executable(laravel_root .. "/vendor/bin/sail") ~= 1 then
    vim.notify("Sail executable not found or not executable. Using standard composer.", 
              vim.log.levels.WARN, { title = "Laravel IDE Helper" })
    
    -- Fall back to standard composer
    cmd = "composer require --dev barryvdh/laravel-ide-helper"
    use_sail = false
    
    -- Update global flag to match
    vim.g.laravel_ide_helper_use_sail = false
  end
  
  vim.notify("Installing Laravel IDE Helper..." .. (use_sail and " (using Sail)" or ""), 
            vim.log.levels.INFO, { title = "Laravel IDE Helper" })
  
  -- We'll just use the nui.nvim popup for all output
  local log_to_buffer = M.create_buffer_logger()
  
  -- Add command info to output
  log_to_buffer({
    "",
    "-------------------------------------------",
    use_sail and "Installing with Laravel Sail..." or "Retrying installation with standard composer...",
    "Command: " .. cmd,
    "Working directory: " .. laravel_root,
    "-------------------------------------------",
    "",
  })
  
  -- Actually run the command
  local job_id = vim.fn.jobstart(cmd, {
    cwd = laravel_root,  -- Use the Laravel root directory
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
          "Laravel IDE Helper installed successfully!",
          "Generating IDE helper files..."
        })
        
        vim.notify("Laravel IDE Helper installed successfully", 
                  vim.log.levels.INFO, { title = "Laravel IDE Helper" })
        
        -- Generate IDE helper files automatically after install
        vim.defer_fn(function()
          -- We're still in the installation process while generating files
          vim.g.laravel_ide_helper_installing = true
          
          -- Save the user's choice about Sail vs standard PHP in a global variable
          vim.g.laravel_ide_helper_use_sail = use_sail
          
          -- IMPORTANT: Set a flag to indicate we've already asked about Sail vs PHP preferences
          -- This will prevent the generate function from asking again
          vim.g.laravel_ide_helper_asked_about_sail = true
          
          if M.debug_mode then
            vim.notify("DEBUG: Preserving Sail preference: " .. tostring(use_sail), 
                      vim.log.levels.DEBUG, { title = "Laravel IDE Helper" })
          end
          
          -- Pass true for force, our sail preference, and buffer ID
          M.generate_ide_helper(true)
        end, 1000) -- Slight delay to let composer finalize
      else
        log_to_buffer({
          "",
          "-------------------------------------------",
          "INSTALLATION FAILED with exit code: " .. code,
          "",
          "Possible next steps:",
          "1. Try running the command manually in your Laravel project directory:",
          "   " .. cmd,
          "2. Check if " .. (use_sail and "Docker/Sail" or "Composer") .. " is properly installed",
          "3. Check network connectivity for package downloads"
        })
        
        -- Clear the installing flag since we're done (with failure)
        vim.g.laravel_ide_helper_installing = false
        
        vim.notify("Failed to install Laravel IDE Helper (exit code: " .. code .. ")",
                 vim.log.levels.ERROR, { title = "Laravel IDE Helper" })
      end
    end
  })
  
  if job_id <= 0 then
    log_to_buffer({
      "Failed to start installation command.",
      "This could mean " .. (use_sail and "Sail" or "Composer") .. " is not accessible."
    })
    
    vim.notify("Failed to start installation command", vim.log.levels.ERROR)
    
    -- Clear the installing flag since we're done (with failure)
    vim.g.laravel_ide_helper_installing = false
    
    return false
  end
  
  return true
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
        M.install_ide_helper()
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
        -- User wants to generate files
        M.generate_ide_helper(false)
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

-- Auto-check and generate IDE Helper files
function M.setup_auto_ide_helper()
  -- Create the command to manually generate IDE helper files
  vim.api.nvim_create_user_command("LaravelGenerateIDEHelper", function()
    M.generate_ide_helper(true)
  end, { desc = "Generate Laravel IDE Helper files" })
  
  -- Create a command to install IDE helper package
  vim.api.nvim_create_user_command("LaravelInstallIDEHelper", function()
    M.install_ide_helper()
  end, { desc = "Install Laravel IDE Helper package" })
  
  -- Create a command to run Artisan commands
  vim.api.nvim_create_user_command("LaravelArtisan", function(opts)
    local args = opts.args
    if args and args ~= "" then
      M.run_artisan_command(args)
    else
      M.run_artisan_command()
    end
  end, { desc = "Run Laravel Artisan command", nargs = "?", complete = "file" })
  
  -- Initialize the global tables for tracking
  vim.g.laravel_ide_helper_checked = vim.g.laravel_ide_helper_checked or {}
  vim.g.laravel_ide_helper_initialized = vim.g.laravel_ide_helper_initialized or false
  vim.g.laravel_ide_helper_installing = vim.g.laravel_ide_helper_installing or false
  vim.g.laravel_ide_helper_use_sail = vim.g.laravel_ide_helper_use_sail or nil
  vim.g.laravel_ide_helper_asked_about_sail = vim.g.laravel_ide_helper_asked_about_sail or false
  
  -- Helper function to dump debug info about IDE Helper state
  local function debug_ide_helper_state()
    if not M.debug_mode then
      return
    end
    
    vim.notify("Laravel IDE Helper State:", vim.log.levels.DEBUG)
    vim.notify("- Initialized: " .. tostring(vim.g.laravel_ide_helper_initialized), vim.log.levels.DEBUG)
    vim.notify("- Installing: " .. tostring(vim.g.laravel_ide_helper_installing), vim.log.levels.DEBUG)
    vim.notify("- Using Sail: " .. tostring(vim.g.laravel_ide_helper_use_sail), vim.log.levels.DEBUG)
    vim.notify("- Asked about Sail: " .. tostring(vim.g.laravel_ide_helper_asked_about_sail), vim.log.levels.DEBUG)
    vim.notify("- Checked projects: " .. vim.inspect(vim.g.laravel_ide_helper_checked), vim.log.levels.DEBUG)
    vim.notify("- Vim fully loaded: " .. tostring(vim.v.vim_did_enter == 1), vim.log.levels.DEBUG)
    
    local lock_file = vim.fn.stdpath("cache") .. "/laravel_ide_helper_prompt.lock"
    vim.notify("- Lock file path: " .. lock_file, vim.log.levels.DEBUG)
    vim.notify("- Lock file exists: " .. tostring(vim.fn.filereadable(lock_file) == 1), vim.log.levels.DEBUG)
  end
  
  -- At startup, make sure to clear the lock file
  if not vim.g.laravel_ide_helper_initialized then
    vim.g.laravel_ide_helper_initialized = true
    
    -- Clear any existing lock file
    local lock_file = vim.fn.stdpath("cache") .. "/laravel_ide_helper_prompt.lock"
    vim.fn.delete(lock_file)
    if M.debug_mode then
      vim.notify("Laravel IDE Helper initialized and lock cleared", vim.log.levels.DEBUG)
    end
    
    -- Set up a one-time handler that runs when Vim is fully loaded
    vim.api.nvim_create_autocmd("VimEnter", {
      callback = function()
        if M.debug_mode then
          vim.notify("Vim fully loaded - ensuring Laravel projects are checked", vim.log.levels.DEBUG)
        end
        -- Trigger the BufEnter event on the current buffer once vim is fully loaded
        vim.defer_fn(function()
          local current_buf = vim.api.nvim_get_current_buf()
          if current_buf and vim.api.nvim_buf_is_valid(current_buf) then
            vim.cmd("doautocmd BufEnter " .. vim.fn.fnameescape(vim.api.nvim_buf_get_name(current_buf)))
          end
        end, 2000) -- Wait 2 seconds after VimEnter
      end,
      once = true
    })
  end
  
  -- Print debug info only if debug mode is enabled
  if M.debug_mode then
    debug_ide_helper_state()
  end
  
  -- Create command to toggle debug mode
  vim.api.nvim_create_user_command("LaravelIDEHelperToggleDebug", function()
    M.toggle_debug_mode()
    if M.debug_mode then
      debug_ide_helper_state()
    end
  end, { desc = "Toggle Laravel IDE Helper debug mode" })
  
  -- Only run on PHP files and only in Laravel projects
  vim.api.nvim_create_autocmd("BufEnter", {
    pattern = "*.php",
    callback = function()
      M.check_laravel_project()
    end
  })
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

-- Helper function to determine if we should use Sail or standard PHP
function M.with_sail_or_php(command)
  local laravel_root = M.find_laravel_root()
  if not laravel_root then
    vim.notify("Not a Laravel project", vim.log.levels.WARN)
    return nil
  end
  
  -- Use local command or sail based on availability and preferences
  local use_sail = M.has_sail() and not M.prefer_standard_php(laravel_root)
  
  local cmd
  if use_sail then
    cmd = "./vendor/bin/sail " .. command
  else
    cmd = command
  end
  
  -- Full command with proper directory
  cmd = "cd " .. vim.fn.shellescape(laravel_root) .. " && " .. cmd
  
  return {
    command = cmd,
    laravel_root = laravel_root,
    use_sail = use_sail
  }
end

-- Run an Artisan command
function M.run_artisan_command(command)
  -- Set up the window for command output
  M.show_ide_helper_window("Laravel Artisan Output")
  
  -- Use the helper to construct the command
  local cmd_info = M.with_sail_or_php("php artisan " .. command)
  if not cmd_info then
    return false
  end
  
  local cmd = cmd_info.command
  local laravel_root = cmd_info.laravel_root
  local use_sail = cmd_info.use_sail
  
  -- Create a buffer logger
  local log_to_buffer = M.create_buffer_logger()
  
  -- Add initial content
  log_to_buffer({
    "Running Laravel Artisan command: " .. command,
    "Working directory: " .. laravel_root,
    "Using " .. (use_sail and "Laravel Sail" or "standard PHP"),
    "-------------------------------------------",
    "",
    "Running: " .. cmd
  })
  
  -- Run the command
  local job_id = vim.fn.jobstart(cmd, {
    stdout_buffered = false,
    stderr_buffered = false,
    on_stdout = function(_, data)
      if data then
        log_to_buffer(data)
      end
    end,
    on_stderr = function(_, data)
      if data then
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
      else
        log_to_buffer({
          "",
          "-------------------------------------------",
          "Command failed with exit code: " .. code,
          "-------------------------------------------",
          ""
        })
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
    return false
  end
  
  return true
end

-- Setup function that configures the plugin with user options
function M.setup(config)
  -- Merge user config with defaults
  M.config = vim.tbl_deep_extend("force", M.config, config or {})
  
  -- Call the auto-detection setup
  M.setup_auto_ide_helper()
end

return M