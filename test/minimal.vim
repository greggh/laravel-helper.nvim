" Minimal init.vim for running tests
" Load only the required plugins and settings

" Clear any existing autocommands
autocmd!

" Set up Lua path to include the test directory
let &runtimepath = getcwd() . ',' . &runtimepath

" Basic settings
set noswapfile
set nobackup
set nowritebackup
set noundofile
set nocompatible

" Only load plugins needed for testing
lua << EndOfLua
-- Set up a minimal env for testing
vim.opt.runtimepath:append(vim.fn.getcwd())
vim.opt.runtimepath:append(vim.fn.getcwd() .. "/spec")
-- Add more paths to find busted
vim.opt.runtimepath:append('/home/runner/.luarocks/share/lua/5.1')
vim.opt.runtimepath:append('/home/runner/.luarocks/lib/lua/5.1')
vim.opt.runtimepath:append('/usr/local/share/lua/5.1')
vim.opt.runtimepath:append('/usr/local/lib/lua/5.1')
vim.opt.runtimepath:append('/usr/share/lua/5.1')
vim.opt.runtimepath:append('/usr/lib/lua/5.1')

-- Make sure we can find Luarocks modules
package.path = package.path .. ";/home/runner/.luarocks/share/lua/5.1/?.lua;/home/runner/.luarocks/share/lua/5.1/?/init.lua"
package.cpath = package.cpath .. ";/home/runner/.luarocks/lib/lua/5.1/?.so"

-- Placeholder for luarocks
pcall(function()
  require('laravel-helper')
end)
EndOfLua