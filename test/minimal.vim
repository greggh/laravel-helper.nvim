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

-- Set minimal debug information
print("Runtime path: " .. vim.o.runtimepath)
print("Current directory: " .. vim.fn.getcwd())

-- We don't load the module here - we'll do it in the test script
EndOfLua