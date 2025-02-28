---@mod laravel-helper.config Configuration management for Laravel Helper
---@brief [[
--- Defines the configuration options for Laravel Helper
--- and validates user-provided configuration.
---@brief ]]

local M = {}

--- Default configuration
--- @table defaults
--- Configuration default values
--- @field auto_detect boolean Whether to automatically detect Laravel projects and offer IDE Helper generation
--- @field docker_timeout number Default timeout for Sail/Docker operations (in milliseconds)
--- @field prefer_sail boolean Whether to automatically use Sail when available
--- @field commands table Array of commands to run for IDE Helper generation
M.defaults = {
  -- Whether to automatically detect Laravel projects and offer IDE Helper generation
  auto_detect = true,

  -- Default timeout for Sail/Docker operations (in milliseconds)
  docker_timeout = 360000, -- 6 minutes

  -- Whether to automatically use Sail when available
  prefer_sail = true,

  -- Commands to run for IDE Helper generation
  commands = {
    "ide-helper:generate", -- PHPDoc generation for Laravel classes
    "ide-helper:models -N", -- PHPDoc generation for models (no write)
    "ide-helper:meta", -- PhpStorm Meta file generation
  },
}

--- Validate configuration values
--- @param config table Configuration table to validate
--- @return boolean is_valid
--- @return string|nil error_message Error message if validation fails
function M.validate(config)
  -- Basic type validation
  local validation_config = {
    auto_detect = { config.auto_detect, "boolean" },
    docker_timeout = { config.docker_timeout, "number" },
    prefer_sail = { config.prefer_sail, "boolean" },
    commands = { config.commands, "table" },
  }

  local ok, err = pcall(vim.validate, validation_config)
  if not ok then
    return false, "Config validation error: " .. err
  end

  -- Additional validation for commands
  if type(config.commands) == "table" then
    for i, cmd in ipairs(config.commands) do
      if type(cmd) ~= "string" then
        return false, string.format("Config validation error: commands[%d] should be a string", i)
      end
    end
  end

  -- Additional validation for docker_timeout
  if config.docker_timeout < 0 then
    return false, "Config validation error: docker_timeout must be a positive number"
  end

  return true, nil
end

--- Merge default configuration with user configuration
--- @param user_config table|nil User-provided configuration values
--- @return table merged_config The merged configuration
--- @return boolean is_valid Whether the configuration is valid
--- @return string|nil error_message Error message if validation fails
function M.merge(user_config)
  local merged = vim.deepcopy(M.defaults)

  if user_config then
    merged = vim.tbl_deep_extend("force", merged, user_config)
  end

  local is_valid, error_message = M.validate(merged)

  return merged, is_valid, error_message
end

return M
