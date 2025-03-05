---@mod laravel-helper.version Version information for Laravel Helper
---@brief [[
--- Defines the semantic version of the Laravel Helper plugin.
--- Used for display and dependency checking.
---@brief ]]

--- @table M
--- Version information for Laravel Helper
--- @field major number Major version (breaking changes)
--- @field minor number Minor version (new features)
--- @field patch number Patch version (bug fixes)
--- @field string function Returns formatted version string

local M = {}

-- Individual version components
M.major = 0
M.minor = 4
M.patch = 2

-- Combined semantic version
M.version = string.format("%d.%d.%d", M.major, M.minor, M.patch)

--- Returns the formatted version string (for backward compatibility)
--- @return string Version string in format "major.minor.patch"
function M.string()
  return M.version
end

return M
