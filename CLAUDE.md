# Laravel Helper Plugin

## Useful Commands

### Git Commands
- `git -C /home/gregg/Projects/neovim/plugins/laravel-helper status` - Check current status
- `git -C /home/gregg/Projects/neovim/plugins/laravel-helper add .` - Stage all changes
- `git -C /home/gregg/Projects/neovim/plugins/laravel-helper commit -m "message"` - Commit changes
- `git -C /home/gregg/Projects/neovim/plugins/laravel-helper push` - Push changes

### Development Commands
- `stylua lua/ -c` - Check Lua formatting
- `stylua lua/` - Format Lua code
- `luacheck lua/` - Run Lua linter
- `nvim --headless -c "lua require('laravel-helper.test').run()"` - Run tests

## Codebase Information

### Config Options
```lua
require("laravel-helper").setup({
  -- Default Laravel environment
  env_file = ".env",
  
  -- PHP executable path
  php_cmd = "php",
  
  -- Artisan command path
  artisan_cmd = "artisan",
  
  -- IDE Helper configuration
  ide_helper = {
    auto_generate = true,       -- Generate IDE helpers on file save
    generate_on_save = true,    -- Generate on file save
    show_notifications = true,  -- Show notifications after generation
  },
  
  -- Telescope integration
  telescope = {
    enable = true,              -- Enable Telescope integration
    keymap = "<leader>la",      -- Keymap to open Laravel actions
  }
})
```

### Project Structure
- `lua/laravel-helper/init.lua` - Main plugin file
- `lua/laravel-helper/ide-helper.lua` - IDE Helper integration
- `lua/laravel-helper/artisan.lua` - Artisan command integration
- `lua/laravel-helper/telescope.lua` - Telescope integration
- `lua/laravel-helper/config.lua` - Configuration module
- `lua/laravel-helper/utils.lua` - Utility functions
- `lua/laravel-helper/test.lua` - Test framework

### Version Management
- Current version: v0.4.2
- Version file: `lua/laravel-helper/version.lua`