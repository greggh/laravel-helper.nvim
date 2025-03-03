---@mod laravel-helper.telescope Telescope integration for Laravel Helper
---@brief [[
--- This module provides Telescope integration for Laravel Helper plugin.
--- It adds various pickers for Laravel-specific functionality.
---@brief ]]

local M = {}

--- Check if telescope is available
local function has_telescope()
  return pcall(require, "telescope")
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

  -- Register the extension with the name "laravel"
  local success, err = pcall(function()
    telescope.register_extension({
      setup = function(ext_config, config)
        -- Any setup needed
      end,
      exports = {
        artisan = function(opts)
          opts = opts or {}

          -- Common artisan commands as initial suggestions
          local commands = {
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
                  }
                end,
              }),
              sorter = conf.generic_sorter(opts),
              attach_mappings = function(prompt_bufnr, map)
                -- Execute the selected artisan command
                local run_command = function()
                  local selection = action_state.get_selected_entry()
                  actions.close(prompt_bufnr)

                  -- Allow user to customize the command with additional parameters
                  vim.ui.input(
                    { prompt = "Artisan command: " .. selection.value .. " ", default = selection.value },
                    function(input)
                      if input and input ~= "" then
                        core.run_artisan_command(input)
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
        end,

        -- Add picker for Laravel routes
        routes = function(opts)
          opts = opts or {}

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
                  }
                end,
              }),
              sorter = conf.generic_sorter(opts),
              previewer = conf.qflist_previewer(opts),
            })
            :find()
        end,

        -- Add picker for Laravel models
        models = function(opts)
          opts = opts or {}

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
          local cmd = string.format("find %s -type f -name '*.php' | sort", vim.fn.shellescape(models_dir))
          local handle = io.popen(cmd)

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
              previewer = conf.file_previewer(opts),
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
        end,
      },
    })
  end)

  if not success then
    vim.notify("Failed to register Laravel Telescope extension: " .. tostring(err), vim.log.levels.DEBUG)
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
