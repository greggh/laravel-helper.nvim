# Project: Laravel Helper Plugin

## Overview
Laravel Helper is a Neovim plugin for Laravel development that provides seamless integration with IDE Helper and enhances the Laravel development experience in Neovim. The plugin offers features for model property completion, PhpDoc generation, relation detection and navigation, and various Laravel-specific utilities.

## Essential Commands
- Run Tests: `env -C /home/gregg/Projects/neovim/plugins/laravel-helper lua tests/run_tests.lua`
- Check Formatting: `env -C /home/gregg/Projects/neovim/plugins/laravel-helper stylua lua/ -c`
- Format Code: `env -C /home/gregg/Projects/neovim/plugins/laravel-helper stylua lua/`
- Run Linter: `env -C /home/gregg/Projects/neovim/plugins/laravel-helper luacheck lua/`
- Build Documentation: `env -C /home/gregg/Projects/neovim/plugins/laravel-helper mkdocs build`

## Project Structure
- `/lua/laravel-helper`: Main plugin code
- `/lua/laravel-helper/ide`: IDE Helper integration
- `/lua/laravel-helper/models`: Model property completion
- `/lua/laravel-helper/commands`: Laravel command integration
- `/after/plugin`: Plugin setup and initialization
- `/tests`: Test files for plugin functionality
- `/doc`: Vim help documentation

## Current Focus
- Integrating nvim-toolkit for shared utilities
- Adding hooks-util as git submodule for development workflow
- Enhancing IDE Helper integration with better PhpDoc generation
- Improving performance for large codebases

## Documentation Links
- Tasks: `/home/gregg/Projects/docs-projects/neovim-ecosystem-docs/tasks/laravel-helper-tasks.md`
- Project Status: `/home/gregg/Projects/docs-projects/neovim-ecosystem-docs/project-status.md`