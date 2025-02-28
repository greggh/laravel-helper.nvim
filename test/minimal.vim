" Minimal init.vim for running tests
" Load only the required plugins and settings

" Clear any existing autocommands
autocmd\!

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

-- Make sure we can find busted
vim.opt.runtimepath:append("/usr/local/share/lua/5.1")
vim.opt.runtimepath:append("/usr/share/lua/5.1")
vim.opt.runtimepath:append(vim.fn.expand("~/.luarocks/share/lua/5.1"))

-- Required for testing
require('laravel-helper')
EndOfLua
