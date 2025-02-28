-- Laravel Helper plugin entry point
if vim.fn.has("nvim-0.8.0") == 0 then
    vim.api.nvim_err_writeln("Laravel Helper requires at least nvim-0.8.0")
    return
end

local ok, laravel_helper = pcall(require, "laravel-helper")

if not ok then
  vim.notify("Failed to load Laravel Helper plugin", vim.log.levels.ERROR)
  return
end

-- Set up the plugin with default configurations
laravel_helper.setup()

-- Register health check command
if vim.fn.exists(":checkhealth") == 2 then
  vim.api.nvim_create_autocmd({"BufEnter", "BufNew"}, {
    pattern = "health://*",
    callback = function()
      -- Defer loading of the health check module to avoid loading everything on startup
      if not _G.laravel_helper_health_reporter then
        _G.laravel_helper_health_reporter = {
          check = function()
            local ok, health = pcall(require, "laravel-helper.health")
            if ok then
              health.check()
            else
              local health = vim.health or require("health")
              local warn = health.warn or health.report_warn
              warn("Could not load Laravel Helper health module")
            end
          end,
        }
      end
    end,
  })
end