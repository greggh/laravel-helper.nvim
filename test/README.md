# Laravel Helper Tests

This directory contains the test setup for Laravel Helper plugin.

## Test Structure

- **minimal.vim**: A minimal Neovim configuration for testing
- **basic_test.vim**: A simple test script that verifies the plugin loads correctly
- (Future) **spec/**: Integration tests using the busted framework

## Running Tests

To run the basic tests:

```bash
make test
```

For more verbose output:

```bash
make test-debug
```

## Test Development

### Current Status

The tests are currently in development. The basic test in `basic_test.vim` is a minimal check that:

1. The plugin can be loaded
2. The plugin has the expected basic structure (version, config, setup function)

### Future Plans

We plan to expand the tests to include:

1. Full unit tests for configuration handling
2. Integration tests for Laravel project detection
3. Mock tests for Artisan command execution
4. Test coverage for IDE Helper integration

## Test Dependencies

The basic tests only require Neovim.

For the future integration tests, we'll need:
- LuaFileSystem
- Busted
- Luassert
- Penlight