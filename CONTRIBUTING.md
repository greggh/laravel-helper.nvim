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

3. Install development dependencies

## Coding Standards

- Follow the existing code style and structure
- Use meaningful variable and function names
- Write clear comments for complex logic
- Keep functions focused and modular
- Add appropriate documentation for new features

## Lua Style Guide

- Use 2 spaces for indentation
- Keep line length reasonable (preferably under 100 characters)
- Use local variables when possible
- Group related functions together
- Follow existing naming conventions:
  - `snake_case` for variables and functions
  - `PascalCase` for classes and constructors

## Testing

Before submitting your changes, please test them thoroughly:

- Test in different environments (Linux, macOS, Windows)
- Test with different PHP and Laravel versions
- Test with and without Laravel Sail
- Test with both Intelephense and phpactor LSPs

## Documentation

When adding new features, please update the documentation:

- Update README.md with any new features, configurations, or dependencies
- Update the Neovim help documentation in doc/laravel-helper.txt
- Include examples of how to use the new features

## License

By contributing to Laravel-Helper.nvim, you agree that your contributions will be licensed under the project's MIT license.

## Questions?

If you have any questions about contributing, please open an issue with your question.

Thank you for contributing to Laravel-Helper.nvim!