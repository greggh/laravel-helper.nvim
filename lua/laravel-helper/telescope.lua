---@mod laravel-helper.telescope Telescope integration for Laravel Helper
---@brief [[
--- This module provides Telescope integration for Laravel Helper plugin.
--- It adds various pickers for Laravel-specific functionality.
---@brief ]]

local M = {}

-- Cache for artisan commands to improve load time
local artisan_commands_cache = nil
local artisan_help_cache = {}

--- Check if telescope is available
local function has_telescope()
  local telescope_available, telescope_module = pcall(require, "telescope")
  if telescope_available then
    -- Only show critical errors, not info messages
    if not telescope_module or not telescope_module.extensions then
      vim.notify("Laravel Helper: Telescope loaded but extensions table doesn't exist!", vim.log.levels.WARN)
    end

    return true
  else
    vim.notify("Laravel Helper: Telescope not found. Some features will be disabled.", vim.log.levels.WARN)
    return false
  end
end

--- Setup the Telescope extension
---@param core table The Laravel Helper core module
---@return nil
function M.setup(core)
  if not has_telescope() then
    return
  end

  local telescope = require("telescope")
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local finders = require("telescope.finders")
  local pickers = require("telescope.pickers")
  local conf = require("telescope.config").values

  -- Define the artisan picker function
  local function artisan_picker(opts)
    opts = opts or {}

    -- Get commands from cache or load them
    local commands = {}

    -- Check for existing cache
    if artisan_commands_cache then
      commands = vim.deepcopy(artisan_commands_cache)
    else
      -- Silently build the cache without notification

      -- Start with common artisan commands as initial suggestions
      commands = {
        "route:list",
        "migrate",
        "migrate:status",
        "db:seed",
        "cache:clear",
        "config:clear",
        "view:clear",
        "key:generate",
        "serve",
        "make:controller",
        "make:model",
        "make:migration",
        "make:seeder",
        "make:middleware",
        "make:policy",
        "make:command",
        "make:request",
        "tinker",
      }

      -- Add available commands if possible by running artisan list
      local laravel_root = core.find_laravel_root()
      if laravel_root then
        local cmd_info = core.with_sail_or_php("php artisan list --raw")
        if cmd_info then
          local handle = io.popen(cmd_info.command)
          if handle then
            for line in handle:lines() do
              if not vim.tbl_contains(commands, line) and line:match("^[%w:-]+$") then
                table.insert(commands, line)
              end
            end
            handle:close()
          end
        end
      end

      -- Sort commands alphabetically
      table.sort(commands)

      -- Store in cache for future use
      artisan_commands_cache = vim.deepcopy(commands)
    end

    -- Set default layout with prompt at the top and preview pane on the right
    opts.theme = nil -- Remove the ivy theme which puts prompt at bottom
    opts.layout_strategy = "horizontal" -- Use horizontal layout for side-by-side preview
    opts.layout_config = {
      horizontal = {
        prompt_position = "top",
        preview_width = 0.5, -- Show preview on the right half
        width = 0.9,
        height = 0.9,
      },
    }

    -- Create or use cached command details for preview
    local command_details = {}

    -- Process command help info, using cache when available
    for _, cmd_name in ipairs(commands) do
      if artisan_help_cache[cmd_name] then
        -- Use cached help info
        command_details[cmd_name] = artisan_help_cache[cmd_name]
      else
        -- Get help info for the command
        local root_dir = core.find_laravel_root()
        if root_dir then
          local info = core.with_sail_or_php("php artisan help " .. cmd_name .. " --no-ansi 2>/dev/null")
          if info then
            local help_output = vim.fn.system(info.command)
            command_details[cmd_name] = help_output
            -- Cache for future use
            artisan_help_cache[cmd_name] = help_output
          end
        end
      end
    end

    pickers
      .new(opts, {
        prompt_title = "Laravel Artisan Commands",
        finder = finders.new_table({
          results = commands,
          entry_maker = function(entry)
            return {
              value = entry,
              display = entry,
              ordinal = entry,
              preview_command = command_details[entry] or "No help available for this command",
            }
          end,
        }),
        sorter = conf.generic_sorter(opts),
        previewer = require("telescope.previewers").new_buffer_previewer({
          title = "Artisan Command Help",
          get_buffer_by_name = function(_, entry)
            return entry.value
          end,
          define_preview = function(self, entry)
            local help_text = entry.preview_command or "No help available for this command"
            vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, vim.split(help_text, "\n"))
          end,
        }),
        attach_mappings = function(prompt_bufnr, map)
          -- Execute the selected artisan command with Telescope output
          local run_command = function()
            local selection = action_state.get_selected_entry()
            actions.close(prompt_bufnr)

            -- Allow user to customize the command with additional parameters
            vim.ui.input(
              { prompt = "Artisan command: " .. selection.value .. " ", default = selection.value },
              function(input)
                if input and input ~= "" then
                  -- Create a function that displays the command output in a Telescope buffer
                  local function show_command_output()
                    local project_root = core.find_laravel_root()
                    if not project_root then
                      vim.notify("Not in a Laravel project", vim.log.levels.WARN)
                      return
                    end

                    -- Get the command with sail or php
                    local cmd_info = core.with_sail_or_php("php artisan " .. input)
                    if not cmd_info then
                      vim.notify("Failed to create command", vim.log.levels.ERROR)
                      return
                    end

                    -- Create a temporary file to capture output
                    local temp_file = os.tmpname()
                    local command_string = cmd_info.command .. " > " .. temp_file .. " 2>&1"

                    -- Show a notification that we're running the command
                    vim.notify("Running: " .. input, vim.log.levels.INFO)

                    -- Run the command and capture output
                    vim.fn.system(command_string)

                    -- Read the output
                    local file = io.open(temp_file, "r")
                    if not file then
                      vim.notify("Failed to read command output", vim.log.levels.ERROR)
                      os.remove(temp_file)
                      return
                    end

                    local content = file:read("*all")
                    file:close()
                    os.remove(temp_file)

                    -- Split content into lines
                    local lines = {}
                    for line in content:gmatch("[^\r\n]+") do
                      table.insert(lines, line)
                    end

                    -- Display the output in a Telescope buffer
                    -- Create a custom picker for command output display
                    local results_picker = pickers.new({
                      initial_mode = "insert", -- Start in insert mode for better focus
                      prompt_title = "Artisan Command: " .. input,
                      finder = finders.new_table({
                        results = lines,
                        entry_maker = function(entry)
                          return {
                            value = entry,
                            display = entry,
                            ordinal = entry,
                          }
                        end,
                      }),
                      -- Use default layout strategy for display
                      theme = nil,
                      layout_strategy = "horizontal",
                      layout_config = {
                        horizontal = {
                          prompt_position = "top",
                          preview_width = 0.5,
                          width = 0.9,
                          height = 0.9,
                        },
                      },
                      -- Use a dummy sorter that doesn't actually do any filtering
                      sorter = {
                        -- Return score 1 for everything - everything passes
                        scoring_function = function()
                          return 1
                        end,
                        -- Highlighter that doesn't highlight anything
                        highlighter = function()
                          return nil
                        end,
                        -- No initialization needed
                        _init = function() end,
                        -- No destruction needed
                        _destroy = function() end,
                        -- No finish needed
                        _finish = function() end,
                        -- Score everything the same, so nothing gets filtered
                        score = function(_, entry, cb_add)
                          cb_add(1, entry)
                        end,
                      },
                      -- No previewer needed for command output
                      previewer = false,
                      -- Setup keymaps to fix the 'A' problem
                      attach_mappings = function(output_bufnr, output_map)
                        -- Block filtering by creating a null filter function
                        require("telescope.actions.set").filter(function()
                          -- Don't actually filter anything when typing
                          return function()
                            return true
                          end
                        end, output_bufnr)

                        -- Use direct keymap to ensure prompt is cleared
                        vim.schedule(function()
                          if vim.api.nvim_buf_is_valid(output_bufnr) then
                            -- Clear the 'A' character from the prompt
                            local prompt_prefix = vim.fn.prompt_getprompt(output_bufnr)
                            vim.api.nvim_buf_set_lines(output_bufnr, 0, -1, false, { prompt_prefix })
                          end
                        end)

                        return true -- keep default mappings
                      end,
                    })

                    -- Display the output
                    results_picker:find()
                  end

                  -- Run our new function instead of the core one
                  show_command_output()
                end
              end
            )
          end

          -- Map enter to run the command
          map("i", "<CR>", run_command)
          map("n", "<CR>", run_command)

          return true
        end,
      })
      :find()
  end

  -- Define the routes picker function
  local function routes_picker(opts)
    opts = opts or {}
    -- Set default layout with prompt at the top and preview pane on the right
    opts.theme = nil -- Remove the ivy theme which puts prompt at bottom
    opts.layout_strategy = "horizontal" -- Use horizontal layout for side-by-side preview
    opts.layout_config = {
      horizontal = {
        prompt_position = "top",
        preview_width = 0.5, -- Show preview on the right half
        width = 0.9,
        height = 0.9,
      },
    }

    -- Get laravel root directory
    local laravel_root = core.find_laravel_root()
    if not laravel_root then
      vim.notify("Not in a Laravel project", vim.log.levels.WARN)
      return
    end

    -- Run route:list command and capture output
    local cmd_info = core.with_sail_or_php("php artisan route:list --json")
    if not cmd_info then
      vim.notify("Failed to get routes", vim.log.levels.ERROR)
      return
    end

    -- Create a temporary file to store the route list
    local temp_file = os.tmpname()
    local output_cmd = cmd_info.command .. " > " .. temp_file

    -- Run the command
    os.execute(output_cmd)

    -- Read the output file
    local routes = {}
    local file = io.open(temp_file, "r")
    if file then
      local content = file:read("*all")
      file:close()

      -- Parse JSON if possible
      local ok, parsed = pcall(vim.json.decode, content)
      if ok and parsed then
        routes = parsed
      end
    end

    -- Clean up temp file
    os.remove(temp_file)

    -- Format routes for display
    local formatted_routes = {}
    for _, route in ipairs(routes) do
      table.insert(formatted_routes, {
        method = route.method or "ANY",
        uri = route.uri or "/",
        name = route.name or "",
        action = route.action or "",
      })
    end

    -- Create the picker
    pickers
      .new(opts, {
        prompt_title = "Laravel Routes",
        finder = finders.new_table({
          results = formatted_routes,
          entry_maker = function(entry)
            local display = string.format("%s %s %s %s", entry.method, entry.uri, entry.name, entry.action)
            return {
              value = entry,
              display = display,
              ordinal = display,
              -- Add extra fields for better preview
              route_method = entry.method,
              route_uri = entry.uri,
              route_name = entry.name,
              route_action = entry.action,
            }
          end,
        }),
        sorter = conf.generic_sorter(opts),
        previewer = require("telescope.previewers").new_buffer_previewer({
          title = "Route Details",
          get_buffer_by_name = function(_, entry)
            return entry.value.uri
          end,
          define_preview = function(self, entry)
            local lines = {
              "Route Details:",
              "-------------",
              "Method:  " .. entry.route_method,
              "URI:     " .. entry.route_uri,
              "Name:    " .. (entry.route_name ~= "" and entry.route_name or "(unnamed)"),
              "Action:  " .. entry.route_action,
              "",
              "URL Example:",
              "------------",
            }

            -- Build example URL
            local url = entry.route_uri:gsub("{([^}]+)}", function(param)
              return ":" .. param
            end)

            table.insert(lines, "http://localhost/" .. url:gsub("^/", ""))

            vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
            vim.api.nvim_buf_set_option(self.state.bufnr, "filetype", "markdown")
          end,
        }),
      })
      :find()
  end

  -- Define the models picker function
  local function models_picker(opts)
    opts = opts or {}
    -- Set default layout with prompt at the top and preview pane on the right
    opts.theme = nil -- Remove the ivy theme which puts prompt at bottom
    opts.layout_strategy = "horizontal" -- Use horizontal layout for side-by-side preview
    opts.layout_config = {
      horizontal = {
        prompt_position = "top",
        preview_width = 0.5, -- Show preview on the right half
        width = 0.9,
        height = 0.9,
      },
    }

    -- Get laravel root directory
    local laravel_root = core.find_laravel_root()
    if not laravel_root then
      vim.notify("Not in a Laravel project", vim.log.levels.WARN)
      return
    end

    -- Find model files
    local models_dir = laravel_root .. "/app/Models"
    if vim.fn.isdirectory(models_dir) ~= 1 then
      -- Try older Laravel structure
      models_dir = laravel_root .. "/app"
    end

    -- Use find command to locate model files
    local find_cmd = string.format("find %s -type f -name '*.php' | sort", vim.fn.shellescape(models_dir))
    local handle = io.popen(find_cmd)

    if not handle then
      vim.notify("Failed to find models", vim.log.levels.ERROR)
      return
    end

    local files = {}
    for file in handle:lines() do
      table.insert(files, file)
    end
    handle:close()

    -- Create the picker
    pickers
      .new(opts, {
        prompt_title = "Laravel Models",
        finder = finders.new_table({
          results = files,
          entry_maker = function(entry)
            local model_name = vim.fn.fnamemodify(entry, ":t:r")
            local rel_path = vim.fn.fnamemodify(entry, ":~:.")

            return {
              value = entry,
              display = model_name .. " (" .. rel_path .. ")",
              ordinal = model_name,
              filename = entry,
            }
          end,
        }),
        sorter = conf.generic_sorter(opts),
        previewer = require("telescope.previewers").new_buffer_previewer({
          title = "Model Preview",
          get_buffer_by_name = function(_, entry)
            return entry.filename
          end,
          define_preview = function(self, entry)
            -- First show the file content
            local filename = entry.filename
            local cat_cmd = "cat " .. vim.fn.shellescape(filename)
            local content = vim.fn.system(cat_cmd)

            -- Set filetype for syntax highlighting
            vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, vim.split(content, "\n"))
            vim.api.nvim_buf_set_option(self.state.bufnr, "filetype", "php")

            -- Try to extract model properties using grep
            local project_root = core.find_laravel_root()
            if project_root then
              -- Use deferreed loading to not block the UI
              vim.defer_fn(function()
                -- Try to find model properties using sail tinker or php
                local model_name = vim.fn.fnamemodify(filename, ":t:r")
                local cmd_info = core.with_sail_or_php(
                  'php artisan tinker --execute="try { '
                    .. "echo 'Model: "
                    .. model_name
                    .. "\\n\\n'; "
                    .. "echo 'Table: ' . (new \\App\\Models\\"
                    .. model_name
                    .. ")->getTable() . '\\n\\n'; "
                    .. "echo 'Fillable: ' . json_encode((new \\App\\Models\\"
                    .. model_name
                    .. ")->getFillable(), JSON_PRETTY_PRINT) . '\\n\\n'; "
                    .. "echo 'Properties: \\n'; "
                    .. "} catch (\\Exception \\$e) { "
                    .. "echo 'Error: ' . \\$e->getMessage(); "
                    .. '}"'
                )

                if cmd_info then
                  -- Run the command to get model info
                  local model_info = vim.fn.system(cmd_info.command)
                  if model_info and #model_info > 0 and not model_info:match("Error:") then
                    -- Add the model info at the top of the buffer
                    local info_lines = vim.split(model_info, "\n")
                    local existing_lines = vim.api.nvim_buf_get_lines(self.state.bufnr, 0, -1, false)
                    local combined_lines = {}

                    -- Add a separator between model info and code
                    table.insert(info_lines, "")
                    table.insert(info_lines, "/* " .. string.rep("-", 50) .. " */")
                    table.insert(info_lines, "/* Source Code: */")
                    table.insert(info_lines, "")

                    -- Combine info with existing content
                    for _, line in ipairs(info_lines) do
                      table.insert(combined_lines, line)
                    end
                    for _, line in ipairs(existing_lines) do
                      table.insert(combined_lines, line)
                    end

                    vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, combined_lines)
                  end
                end
              end, 100) -- Small delay to allow preview to show first
            end
          end,
        }),
        attach_mappings = function(prompt_bufnr, map)
          actions.select_default:replace(function()
            local selection = action_state.get_selected_entry()
            actions.close(prompt_bufnr)
            vim.cmd("edit " .. selection.value)
          end)
          return true
        end,
      })
      :find()
  end

  -- Register the extension with the name "laravel" directly in the Telescope namespace
  -- This is a simple approach to avoid Telescope extension loading issues

  -- First make sure the extensions table exists
  if not telescope.extensions then
    telescope.extensions = {}
  end

  -- Create our extension directly
  telescope.extensions.laravel = {
    artisan = artisan_picker,
    routes = routes_picker,
    models = models_picker,
  }

  -- Only show error if registration fails
  if not telescope.extensions.laravel then
    vim.notify("Laravel Helper: Failed to register Telescope extension 'laravel'", vim.log.levels.ERROR)
  end
end

--- Override run_artisan_command to use Telescope if available
---@param core table The Laravel Helper core module
function M.override_artisan_command(core)
  -- Keep a reference to the original function
  local original_run_artisan_command = core.run_artisan_command

  -- Override with new function that uses Telescope
  core.run_artisan_command = function(command)
    if not has_telescope() then
      return original_run_artisan_command(command)
    end

    if not command then
      -- If no command was provided, use Telescope picker if extension is registered
      local has_laravel_ext, telescope_ext = pcall(function()
        return require("telescope").extensions.laravel
      end)

      if has_laravel_ext and telescope_ext then
        telescope_ext.artisan()
      else
        -- Fallback to original method if extension isn't registered
        vim.notify("Laravel Telescope extension not loaded properly, falling back to basic input", vim.log.levels.DEBUG)
        return original_run_artisan_command(command)
      end
    else
      -- If command was provided, use original function
      return original_run_artisan_command(command)
    end
  end
end

return M
