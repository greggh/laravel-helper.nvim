# Contributing to Laravel-Helper.nvim

Thank you for your interest in contributing to Laravel-Helper.nvim! This document provides guidelines and instructions to help you contribute effectively.

## Code of Conduct

By participating in this project, you agree to maintain a respectful and inclusive environment for everyone.

## Ways to Contribute

There are several ways you can contribute to Laravel-Helper.nvim:

- Reporting bugs
- Suggesting enhancements
- Submitting pull requests
- Improving documentation
- Sharing your experience using the plugin

## Reporting Issues

Before submitting an issue, please:

1. Check if the issue already exists in the [issues section](https://github.com/greggh/laravel-helper.nvim/issues)
2. Use the issue template if available
3. Include as much relevant information as possible:
   - Neovim version
   - Laravel version
   - Operating system
   - Steps to reproduce the issue
   - Expected vs. actual behavior
   - Any error messages or logs

## Pull Request Process

1. Fork the repository
2. Create a new branch for your changes
3. Make your changes, following the coding standards below
4. Test your changes thoroughly
5. Submit a pull request with a clear description of the changes

For significant changes, please open an issue first to discuss your proposed changes.

## Development Setup

To set up a development environment:

1. Clone your fork of the repository
```bash
git clone https://github.com/YOUR_USERNAME/laravel-helper.nvim.git
```

2. Link the repository to your Neovim plugins directory or use your plugin manager's development mode

3. Set up the Git hooks for automatic code formatting:
```bash
./scripts/setup-hooks.sh
```

This will set up pre-commit hooks to automatically format Lua code using StyLua before each commit.

### Development Dependencies

- [StyLua](https://github.com/JohnnyMorganz/StyLua) - For automatic code formatting
- [LuaCheck](https://github.com/mpeterv/luacheck) - For static analysis (linting)
- [LDoc](https://github.com/lunarmodules/LDoc) - For documentation generation (optional)

## Coding Standards

- Follow the existing code style and structure
- Use meaningful variable and function names
- Write clear comments for complex logic
- Keep functions focused and modular
- Add appropriate documentation for new features

## Lua Style Guide

We use [StyLua](https://github.com/JohnnyMorganz/StyLua) to enforce consistent formatting of the codebase. The formatting is done automatically via pre-commit hooks if you've set them up using the script provided.

Key style guidelines:
- Configuration is in `stylua.toml` at the project root
- Maximum line length is 120 characters
- Use 2 spaces for indentation
- Use local variables when possible
- Group related functions together
- Follow existing naming conventions:
  - `snake_case` for variables and functions
  - `PascalCase` for classes and constructors

Files are linted using [LuaCheck](https://github.com/mpeterv/luacheck) according to `.luacheckrc`.

## Testing

Before submitting your changes, please test them thoroughly:

### Running Tests

You can run the test suite using the Makefile:

```bash
# Run all tests
make test

# Run specific test groups
make test-basic    # Run only basic functionality tests
make test-config   # Run only configuration tests
```

See `test/README.md` for more details on the different test types.

The CI workflow will automatically run these tests against multiple Neovim versions (0.8.0, 0.9.0, stable, and nightly) to ensure compatibility.

### Manual Testing

- Test in different environments (Linux, macOS, Windows if possible)
- Test with different PHP and Laravel versions
- Test with and without Laravel Sail
- Test with both Intelephense and phpactor LSPs
- Use the minimal test configuration (`tests/minimal-init.lua`) to verify your changes in isolation

## Documentation

When adding new features, please update the documentation:

- Update README.md with any new features, configurations, or dependencies
- Update the Neovim help documentation in doc/laravel-helper.txt
- Include examples of how to use the new features
- Add appropriate LDoc annotations if you're modifying the Lua code

The CI workflow will automatically generate documentation using LDoc when changes are pushed to the main branch.

## License

By contributing to Laravel-Helper.nvim, you agree that your contributions will be licensed under the project's MIT license.

## Questions?

If you have any questions about contributing, please open an issue with your question.

Thank you for contributing to Laravel-Helper.nvim!