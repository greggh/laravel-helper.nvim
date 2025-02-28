-- Minimal configuration for testing the plugin
local plugin_dir = vim.fn.expand("~/Projects/neovim/plugins/laravel-helper")

-- Add the plugin directory to runtimepath
vim.opt.runtimepath:append(plugin_dir)

-- Add nui.nvim dependency to runtimepath
vim.opt.runtimepath:append(vim.fn.expand("~/Projects/neovim/plugins/nui.nvim"))

-- Load the plugin
vim.cmd("runtime plugin/laravel-helper.lua")