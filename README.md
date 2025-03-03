<div align="center">

# Laravel-Helper.nvim

[![CI](https://img.shields.io/github/actions/workflow/status/greggh/laravel-helper.nvim/ci.yml?branch=main&style=flat-square&logo=github)](https://github.com/greggh/laravel-helper.nvim/actions/workflows/ci.yml)
[![GitHub License](https://img.shields.io/github/license/greggh/laravel-helper.nvim?style=flat-square)](https://github.com/greggh/laravel-helper.nvim/blob/main/LICENSE)
[![GitHub Stars](https://img.shields.io/github/stars/greggh/laravel-helper.nvim?style=flat-square)](https://github.com/greggh/laravel-helper.nvim/stargazers)
[![GitHub Issues](https://img.shields.io/github/issues/greggh/laravel-helper.nvim?style=flat-square)](https://github.com/greggh/laravel-helper.nvim/issues)
[![Neovim Version](https://img.shields.io/badge/Neovim-0.8%2B-blueviolet?style=flat-square&logo=neovim)](https://github.com/neovim/neovim)
[![Tests](https://img.shields.io/badge/Tests-40%20passing-success?style=flat-square&logo=github-actions)](https://github.com/greggh/laravel-helper.nvim/actions/workflows/ci.yml)
[![Version](https://img.shields.io/badge/Version-0.4.1-blue?style=flat-square)](https://github.com/greggh/laravel-helper.nvim/releases/tag/v0.4.1)

*A comprehensive Laravel development environment for Neovim with focus on IDE Helper integration*

[Features](#features) • 
[Requirements](#requirements) • 
[Installation](#installation) • 
[Configuration](#configuration) • 
[Usage](#usage) • 
[Contributing](#contributing) • 
[Discussions](https://github.com/greggh/laravel-helper.nvim/discussions)

</div>

> ⚠️ **WARNING: PRE-ALPHA SOFTWARE** ⚠️  
> This plugin is in very early development (first commit, day one). It is currently in the "it works on my machine" phase and has not been thoroughly tested across different environments. Use at your own risk.

## Table of Contents

- [Goals](#goals)
- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage](#usage)
  - [Key Mappings](#key-mappings)
  - [Commands](#commands)
  - [Functions](#functions)
- [Contributing](#contributing)
- [License](#license)
- [Community](#community)
- [Acknowledgements](#acknowledgements)

## Goals

The primary goal of this plugin is to create a unified Laravel development experience in Neovim by integrating with the broader Laravel for Neovim ecosystem. This means:

- Depending on and configuring other valuable Laravel/PHP plugins to create a cohesive experience
- Adding support for Blade, Alpine, Tailwind, and other Laravel-adjacent technologies
- Providing sensible defaults while allowing customization

Projects we aim to integrate with include:
- [blade-nav.nvim](https://github.com/Dkendal/blade-nav.nvim) - Blade syntax highlighting and navigation
- [blade-formatter](https://github.com/shufo/blade-formatter) - Code formatting for Blade templates
- [laravel.nvim](https://github.com/adalessa/laravel.nvim) - Laravel-specific utilities
- [tree-sitter-blade](https://github.com/EmranMR/tree-sitter-blade) - Enhanced Blade syntax parsing
- [tailwind-tools.nvim](https://github.com/jcha0713/tailwind-tools.nvim) - Tailwind CSS integration
- [nvim-dap](https://github.com/mfussenegger/nvim-dap) with [php-debug-adapter](https://github.com/xdebug/vscode-php-debug) - Debugging support
- [conform.nvim](https://github.com/stevearc/conform.nvim) setup for [Pint](https://github.com/laravel/pint) and [php-cs-fixer](https://github.com/PHP-CS-Fixer/PHP-CS-Fixer) - Code formatting
- [neotest-pest](https://github.com/V13Axel/neotest-pest) - Testing framework integration
- [LuaSnip](https://github.com/L3MON4D3/LuaSnip) - Laravel-specific snippets
- Support for both [Intelephense](https://github.com/bmewburn/intelephense-docs) and [phpactor](https://github.com/phpactor/phpactor) LSPs

## Features

- Automatic detection of Laravel projects
- IDE Helper integration with support for PHP and Laravel Sail
- Automatic installation and generation of IDE Helper files
- Artisan command integration with Telescope fuzzy finding
- Laravel routes and models browsing with Telescope
- Support for running in Docker/Sail environments
- Advanced debugging features
- Comprehensive testing suite (40 tests)

## Requirements

- Neovim >= 0.8.0
- PHP installed locally, or Laravel Sail configured

### Core Dependencies
- [nui.nvim](https://github.com/MunifTanjim/nui.nvim) - UI components for improved interface

### Recommended Dependencies
The following plugins provide the enhanced command interface with subcommands and automatic help:
- [mega.cmdparse](https://github.com/ColinKennedy/mega.cmdparse) - Command parsing and interface (optional but recommended)
- [mega.logging](https://github.com/ColinKennedy/mega.logging) - Logging utilities (required by mega.cmdparse)
- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) - Enhanced fuzzy finder for Artisan commands, routes, and models

Without mega.cmdparse, the plugin will fall back to the legacy command interface.
Without telescope.nvim, the plugin will fall back to simple input prompts for Artisan commands.

### Recommended Laravel Ecosystem Plugins
For a complete Laravel development environment, we recommend the following plugins:
- [lazy.nvim](https://github.com/folke/lazy.nvim) - Plugin manager
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) - Lua utilities
- [nvim-nio](https://github.com/nvim-neotest/nvim-nio) - Async IO
- [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) - LSP configuration
- [mason.nvim](https://github.com/williamboman/mason.nvim) - Package manager
- [mason-lspconfig.nvim](https://github.com/williamboman/mason-lspconfig.nvim) - Mason LSP integration
- [mason-tool-installer](https://github.com/WhoIsSethDaniel/mason-tool-installer) - Tool installer
- [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) - Syntax parsing
- [nvim-ts-autotag](https://github.com/windwp/nvim-ts-autotag) - Auto close/rename tags
- [nvim-treesitter-context](https://github.com/nvim-treesitter/nvim-treesitter-context) - Code context
- [nvim-treesitter-textobjects](https://github.com/nvim-treesitter/nvim-treesitter-textobjects) - Text objects
- [conform.nvim](https://github.com/stevearc/conform.nvim) - Code formatting
- [nvim-lint](https://github.com/mfussenegger/nvim-lint) - Linting
- [nvim-dap](https://github.com/mfussenegger/nvim-dap) - Debug adapter
- [nvim-dap-ui](https://github.com/rcarriga/nvim-dap-ui) - Debug UI
- [nvim-dap-virtual-text](https://github.com/theHamsta/nvim-dap-virtual-text) - Debug virtual text
- [neotest](https://github.com/nvim-neotest/neotest) - Testing framework
- [neotest-plenary](https://github.com/nvim-neotest/neotest-plenary) - Plenary test adapter
- [neotest-pest](https://github.com/V13Axel/neotest-pest) - Pest test adapter
- [LuaSnip](https://github.com/L3MON4D3/LuaSnip) - Snippet engine
- [friendly-snippets](https://github.com/rafamidriz/friendly-snippets) - Snippet collection
- [blink.cmp](https://github.com/saghen/blink.cmp) - Blink CMP integration
- [blink.compat](https://github.com/saghen/blink.compat) - Blink compatibility
- [blink-ripgrep.nvim](https://github.com/mikavilpas/blink-ripgrep.nvim) - Blink ripgrep integration
- [cmp-cmdline-history](https://github.com/dmitmel/cmp-cmdline-history) - Command line history
- [blade-nav.nvim](https://github.com/Dkendal/blade-nav.nvim) - Blade syntax highlighting and navigation
- [tree-sitter-blade](https://github.com/EmranMR/tree-sitter-blade) - Enhanced Blade syntax parsing
- [phpactor](https://github.com/phpactor/phpactor) - PHP language server

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "greggh/laravel-helper.nvim",
  dependencies = {
    -- Enhanced command interface
    "ColinKennedy/mega.cmdparse",  -- Optional but recommended
    "ColinKennedy/mega.logging",   -- Required by mega.cmdparse
    
    -- Core dependencies
    "MunifTanjim/nui.nvim",
    
    -- Telescope integration
    "nvim-telescope/telescope.nvim",
    "nvim-telescope/telescope-fzf-native.nvim",
    "nvim-lua/plenary.nvim",       -- Required by telescope
    
    -- Additional recommended Laravel ecosystem dependencies
    "folke/lazy.nvim",
    "nvim-neotest/nvim-nio",
    "neovim/nvim-lspconfig",
    "williamboman/mason.nvim",
    "williamboman/mason-lspconfig.nvim",
    "WhoIsSethDaniel/mason-tool-installer",
    "nvim-treesitter/nvim-treesitter",
    "windwp/nvim-ts-autotag",
    "nvim-treesitter/nvim-treesitter-context",
    "nvim-treesitter/nvim-treesitter-textobjects",
    "stevearc/conform.nvim",
    "mfussenegger/nvim-lint",
    "mfussenegger/nvim-dap",
    "rcarriga/nvim-dap-ui",
    "theHamsta/nvim-dap-virtual-text",
    "nvim-neotest/neotest",
    "nvim-neotest/neotest-plenary",
    "V13Axel/neotest-pest",
    "L3MON4D3/LuaSnip",
    "rafamidriz/friendly-snippets",
    "saghen/blink.cmp",
    "saghen/blink.compat",
    "mikavilpas/blink-ripgrep.nvim",
    "dmitmel/cmp-cmdline-history",
  },
  ft = { "php", "blade" },
  config = function()
    require("laravel-helper").setup({
      -- Optional configuration options
    })
  end,
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  'greggh/laravel-helper.nvim',
  requires = {
    -- Enhanced command interface
    'ColinKennedy/mega.cmdparse',  -- Optional but recommended
    'ColinKennedy/mega.logging',   -- Required by mega.cmdparse
    
    -- Core dependencies
    'MunifTanjim/nui.nvim',
  },
  config = function()
    require('laravel-helper').setup()
  end
}
```

### Using [vim-plug](https://github.com/junegunn/vim-plug)

```viml
" Core and enhanced command interface
Plug 'MunifTanjim/nui.nvim'
Plug 'ColinKennedy/mega.logging'   " Required by mega.cmdparse
Plug 'ColinKennedy/mega.cmdparse'  " Optional but recommended
Plug 'greggh/laravel-helper.nvim'

" Then in your init.vim
lua require('laravel-helper').setup()
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

### Commands

#### Enhanced Command Structure (requires mega.cmdparse)

When the plugin is installed with the optional mega.cmdparse dependency, it provides a structured command interface:

```
:Laravel artisan <args>            - Run Laravel Artisan commands
:Laravel ide-helper generate       - Generate Laravel IDE Helper files
:Laravel ide-helper generate --use-sail - Generate IDE Helper files using Sail
:Laravel ide-helper install        - Install Laravel IDE Helper package
:Laravel ide-helper debug          - Toggle debug mode for IDE Helper
```

Use `:Laravel --help` to see all available commands and their descriptions.

#### Telescope Integration (requires telescope.nvim)

When the plugin is installed with telescope.nvim, it provides enhanced selection interfaces:

```
:LaravelTelescope artisan         - Browse and run Artisan commands with fuzzy finder
:LaravelTelescope routes          - Browse Laravel routes with fuzzy finder
:LaravelTelescope models          - Browse Laravel models with fuzzy finder
```

The plugin also automatically uses Telescope for the Artisan command input when you call functions like `run_artisan_command()` without a specific command.

#### Legacy Commands

```
:LaravelArtisan <args>             - Run Laravel Artisan commands
:LaravelGenerateIDEHelper [php|sail] - Generate Laravel IDE Helper files 
:LaravelInstallIDEHelper           - Install Laravel IDE Helper package
:LaravelIDEHelperToggleDebug       - Toggle debug mode for IDE Helper
```

### Functions

- `is_laravel_project()`: Check if current directory is a Laravel project
- `install_ide_helper()`: Install Laravel IDE Helper package
- `generate_ide_helper(force)`: Generate IDE Helper files
- `toggle_debug_mode()`: Toggle detailed debug output
- `run_artisan_command(command)`: Run an artisan command with output capture
- `with_sail_or_php(command)`: Run a command using Sail when available, falling back to PHP
- `get_sail_or_php_command(command)`: Get the command string to run with either Sail or standard PHP

## Contributing

Contributions are welcome! Please check out our [contribution guidelines](CONTRIBUTING.md) for details on how to get started.

For a complete guide on setting up a development environment, installing all required tools, and understanding the project structure, please refer to [DEVELOPMENT.md](DEVELOPMENT.md).

### Development Setup

The project includes comprehensive setup for development:

- Complete installation instructions for all platforms in [DEVELOPMENT.md](DEVELOPMENT.md)
- Pre-commit hooks for code quality
- Testing framework with 40 comprehensive tests
- Linting and formatting tools
- Weekly dependency updates workflow

```bash
# Run tests
make test

# Check code quality
make lint

# Set up pre-commit hooks
scripts/setup-hooks.sh

# Format code
make format
```

### Code Formatting

- Lua code is formatted using StyLua according to the rules in `.stylua.toml`
- Maximum line length is 120 characters
- Files are linted using Luacheck according to `.luacheckrc`

## License

[MIT License](LICENSE)

## Community

- [GitHub Discussions](https://github.com/greggh/laravel-helper.nvim/discussions) - Get help, share ideas, and connect with other users
- [GitHub Issues](https://github.com/greggh/laravel-helper.nvim/issues) - Report bugs or suggest features
- [GitHub Pull Requests](https://github.com/greggh/laravel-helper.nvim/pulls) - Contribute to the project

## Acknowledgements

- [Laravel IDE Helper](https://github.com/barryvdh/laravel-ide-helper) - The core functionality this plugin integrates with
- [Laravel](https://laravel.com/) - The PHP framework this plugin enhances for Neovim
- [nui.nvim](https://github.com/MunifTanjim/nui.nvim) - Core UI components dependency
- [mega.cmdparse](https://github.com/ColinKennedy/mega.cmdparse) - Enhanced command interface
- [Plenary.nvim](https://github.com/nvim-lua/plenary.nvim) - Testing framework
- [Semantic Versioning](https://semver.org/) - Versioning standard used in this project
- [Contributor Covenant](https://www.contributor-covenant.org/) - Code of Conduct standard
- [Keep a Changelog](https://keepachangelog.com/) - Changelog format
- [LuaCATS](https://luals.github.io/wiki/annotations/) - Type annotations for better IDE support
- [StyLua](https://github.com/JohnnyMorganz/StyLua) - Lua code formatter
- [Luacheck](https://github.com/lunarmodules/luacheck) - Lua static analyzer and linter

---

<div align="center">
  <p>Made with ❤️ by <a href="https://github.com/greggh">greggh</a></p>
</div>