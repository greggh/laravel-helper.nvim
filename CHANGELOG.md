# Changelog

All notable changes to Laravel Helper will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.3.0] - 2025-03-01

### Added
- Comprehensive test suite with proper error reporting
- GitHub Actions workflow for continuous integration
- Pre-commit hooks for code quality

### Changed
- Improved error handling and module loading approach
- Enhanced code organization

### Fixed
- Various linting issues in CI workflows
- Missing configuration in .luacheckrc for Lua globals
- Code formatting issues with StyLua

## [0.2.0] - 2023-02-28

### Added
- Enhanced command structure using mega.cmdparse
- Nested subcommands for Laravel articulations (artisan, ide-helper)
- Structured help documentation and command completion
- Health checks for PHP and Composer
- Configuration validation
- Type annotations throughout the codebase
- Version tracking and semantic versioning

### Changed
- Improved lazy loading for better performance
- Better documentation with installation examples for all plugin managers
- Updated minimum Neovim version to 0.8.0
- Reorganized code into modules for better maintainability

### Fixed
- Fixed potential issues with configuration handling
- Added backward compatibility for legacy commands

## [0.1.0] - 2023-02-15

### Added
- Initial release
- Laravel project detection
- IDE Helper integration
- Artisan command execution
- Support for Laravel Sail
