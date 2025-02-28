---@mod laravel-helper.health Laravel Helper Health Checks
---@brief [[
--- Health checks for the Laravel Helper plugin
--- Run with :checkhealth laravel-helper
---@brief ]]

local M = {}

--- Run health checks for Laravel Helper
---@return nil
function M.check()
  -- Required vim modules for health checks
  local health = vim.health or require("health")
  local start = health.start or health.report_start
  local ok = health.ok or health.report_ok
  local warn = health.warn or health.report_warn
  local error = health.error or health.report_error
  local info = health.info or health.report_info

  start("Laravel Helper")

  -- Check PHP installation
  if vim.fn.executable("php") == 1 then
    ok("PHP is installed")
  else
    error("PHP is not installed", {
      "Install PHP: https://www.php.net/downloads",
    })
  end

  -- Check Composer installation
  if vim.fn.executable("composer") == 1 then
    ok("Composer is installed")
  else
    warn("Composer is not installed", {
      "Install Composer: https://getcomposer.org/download/",
    })
  end

  -- Check for mega.cmdparse
  local has_mega_cmdparse, _ = pcall(require, "mega.cmdparse")
  if has_mega_cmdparse then
    ok("mega.cmdparse is installed - enhanced commands available")
  else
    warn("mega.cmdparse is not installed", {
      "Install mega.cmdparse for enhanced command experience:",
      "Using lazy.nvim: { 'ColinKennedy/mega.cmdparse', dependencies = { 'ColinKennedy/mega.logging' } }",
      "Using packer.nvim: use { 'ColinKennedy/mega.cmdparse', requires = { 'ColinKennedy/mega.logging' } }",
    })
  end

  -- Check for current Laravel project
  local core = require("laravel-helper.core")
  if core.is_laravel_project() then
    local root = core.find_laravel_root()
    ok("Current project is a Laravel project: " .. root)

    -- Check if IDE Helper is installed
    if core.is_ide_helper_installed() then
      ok("Laravel IDE Helper is installed")
    else
      info("Laravel IDE Helper is not installed in this project", {
        "Run :Laravel ide-helper install to install it",
      })
    end

    -- Check if Sail is available
    if core.has_sail() then
      ok("Laravel Sail is available")
    else
      info("Laravel Sail is not available in this project")
    end
  else
    info("Current directory is not a Laravel project")
  end
end

return M
