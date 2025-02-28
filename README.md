# Laravel-Helper.nvim

> ⚠️ **WARNING: PRE-ALPHA SOFTWARE** ⚠️  
> This plugin is in very early development (first commit, day one). It is currently in the "it works on my machine" phase and has not been thoroughly tested across different environments. Use at your own risk.

A Neovim plugin for Laravel development, with focus on Laravel IDE Helper integration.

## Features

- Automatic detection of Laravel projects
- IDE Helper integration with support for PHP and Laravel Sail
- Automatic installation and generation of IDE Helper files
- Artisan command integration
- Support for running in Docker/Sail environments
- Advanced debugging features

## Requirements

- Neovim >= 0.10.0
- [nui.nvim](https://github.com/MunifTanjim/nui.nvim) for the UI components
- PHP installed locally, or Laravel Sail configured

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "greggh/laravel-helper.nvim",
  dependencies = {
    "MunifTanjim/nui.nvim",
  },
  ft = { "php" },
  config = function()
    require("laravel-helper").setup({
      -- Optional configuration options
    })
  end,
}
```

## Configuration

```lua
require("laravel-helper").setup({
  -- Whether to automatically detect Laravel projects and offer IDE Helper generation
  auto_detect = true,
  
  -- Default timeout for Sail/Docker operations (in milliseconds)
  docker_timeout = 360000, -- 6 minutes
  
  -- Whether to automatically use Sail when available
  prefer_sail = true,
  
  -- Commands to run for IDE Helper generation
  commands = {
    "ide-helper:generate",    -- PHPDoc generation for Laravel classes
    "ide-helper:models",      -- PHPDoc generation for models
    "ide-helper:meta",        -- PhpStorm Meta file generation
  }
})
```

## Usage

### Key Mappings

By default, the plugin doesn't set any key mappings. You can add your own like this:

```lua
vim.api.nvim_create_autocmd("FileType", {
  pattern = "php",
  callback = function()
    -- Only set up mappings in Laravel projects
    if require("laravel-helper").is_laravel_project() then
      local opts = { buffer = 0, silent = true }
      
      -- Generate IDE Helper files
      vim.keymap.set("n", "<leader>lph", function()
        require("laravel-helper").generate_ide_helper(true)
      end, vim.tbl_extend("force", opts, { desc = "Generate Laravel IDE Helper files" }))
      
      -- Install IDE Helper if not already installed
      vim.keymap.set("n", "<leader>lpi", function()
        require("laravel-helper").install_ide_helper()
      end, vim.tbl_extend("force", opts, { desc = "Install Laravel IDE Helper" }))
      
      -- Toggle debug mode for Laravel IDE Helper
      vim.keymap.set("n", "<leader>lpd", function()
        require("laravel-helper").toggle_debug_mode()
      end, vim.tbl_extend("force", opts, { desc = "Toggle Laravel IDE Helper debug mode" }))
      
      -- Run Artisan commands
      vim.keymap.set("n", "<leader>lpa", function()
        require("laravel-helper").run_artisan_command()
      end, vim.tbl_extend("force", opts, { desc = "Run Laravel Artisan command" }))
    end
  end,
})
```

## Functions

- `is_laravel_project()`: Check if current directory is a Laravel project
- `install_ide_helper()`: Install Laravel IDE Helper package
- `generate_ide_helper(force)`: Generate IDE Helper files
- `toggle_debug_mode()`: Toggle detailed debug output
- `run_artisan_command()`: Run an artisan command with output capture

## License

MIT