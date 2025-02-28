---
name: Bug report
about: Create a report to help improve Laravel-Helper.nvim
title: '[BUG] '
labels: bug
assignees: ''
---

## Bug Description

A clear and concise description of what the bug is.

## Steps To Reproduce

1. Go to '...'
2. Run command '....'
3. See error

## Expected Behavior

A clear and concise description of what you expected to happen.

## Screenshots

If applicable, add screenshots to help explain your problem.

## Environment

- OS: [e.g. Ubuntu 22.04, macOS 13.0, Windows 11]
- Neovim version: [e.g. 0.10.0]
- PHP version: [e.g. 8.2.0]
- Laravel version: [e.g. 10.0]
- Using Laravel Sail: [Yes/No]
- LSP: [Intelephense/phpactor/both]

## Plugin Configuration

```lua
-- Your Laravel-Helper.nvim configuration here
require("laravel-helper").setup({
  -- Your configuration options
})
```

## Additional Context

Add any other context about the problem here, such as:
- Error messages from Neovim (:messages)
- Logs from Laravel IDE Helper (enable debug mode first)
- Any recent changes to your setup

## Minimal Reproduction

For faster debugging, try to reproduce the issue using our minimal configuration:

1. Create a new directory for testing
2. Copy `tests/minimal-init.lua` from this repo to your test directory
3. Start Neovim with this minimal config:
   ```bash
   nvim --clean -u minimal-init.lua
   ```
4. Try to reproduce the issue with this minimal setup