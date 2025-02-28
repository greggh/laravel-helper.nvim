-- Laravel Helper plugin entry point
local ok, laravel_helper = pcall(require, "laravel-helper")

if not ok then
  vim.notify("Failed to load Laravel Helper plugin", vim.log.levels.ERROR)
  return
end

-- Set up the plugin with default configurations
laravel_helper.setup()