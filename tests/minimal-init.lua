-- Minimal configuration for testing the Laravel Helper plugin
-- Used for bug reproduction and testing

-- Detect the plugin directory (works whether run from plugin root or a different directory)
local function get_plugin_path()
  local debug_info = debug.getinfo(1, "S")
  local source = debug_info.source

  if string.sub(source, 1, 1) == "@" then
    source = string.sub(source, 2)
    -- If we're running directly from the plugin
    if string.find(source, "/tests/minimal%-init%.lua$") then
      local plugin_dir = string.gsub(source, "/tests/minimal%-init%.lua$", "")
      return plugin_dir
    else
      -- For a copied version, assume it's run directly from the dir it's in
      return vim.fn.getcwd()
    end
  end
  return vim.fn.getcwd()
end

local plugin_dir = get_plugin_path()
print("Plugin directory: " .. plugin_dir)

-- Basic settings
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.writebackup = false
vim.opt.undofile = false

-- Add the plugin directory to runtimepath
vim.opt.runtimepath:append(plugin_dir)

-- Print current runtime path for debugging
print("Runtime path: " .. vim.o.runtimepath)

-- Load the plugin
vim.cmd("runtime plugin/laravel-helper.lua")

-- Set up minimal UI elements
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.signcolumn = "yes"

print("Laravel Helper minimal test environment loaded.")
print("- Type :messages to see any error messages")
print("- Type :checkhealth laravel-helper to check plugin health")
