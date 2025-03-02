# Laravel Helper Testing

This directory contains resources for automated and manual testing.

## Automated Tests

The plugin includes a comprehensive test suite with 40 tests covering:
- Core module functionality
- Command registration
- Configuration validation
- Health checks
- Window navigation
- Error handling

Tests run automatically via:
- Pre-commit hooks (when committing changes)
- CI workflow (when pushing to GitHub)
- Manual execution with `make test`

## Minimal Test Configuration

The `minimal-init.lua` file provides a minimal Neovim configuration for testing the Laravel Helper plugin in isolation. This standardized initialization file matches the format used in related Neovim projects and is useful for:

1. Reproducing and debugging issues
2. Testing new features in a clean environment
3. Providing minimal reproducible examples when reporting bugs

## Usage

### Option 1: Run directly from the plugin directory

```bash
# From the plugin root directory
nvim --clean -u tests/minimal-init.lua
```

### Option 2: Copy to a separate directory for testing

```bash
# Create a test directory
mkdir ~/laravel-test
cp tests/minimal-init.lua ~/laravel-test/
cd ~/laravel-test

# Run Neovim with the minimal config
nvim --clean -u minimal-init.lua
```

## Troubleshooting

The minimal configuration:
- Attempts to auto-detect the plugin directory
- Sets up basic Neovim settings (no swap files, etc.)
- Loads only the Laravel Helper plugin (no dependencies)
- Shows line numbers and sign column

To see error messages:
```
:messages
```

To check plugin health:
```
:checkhealth laravel-helper
```

## Reporting Issues

When reporting issues, please include the following information:
1. Steps to reproduce the issue using this minimal config
2. Any error messages from `:messages`
3. Output from `:checkhealth laravel-helper`