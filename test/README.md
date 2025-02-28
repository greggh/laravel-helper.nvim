# Laravel Helper Tests

This directory contains the test setup for Laravel Helper plugin.

## Test Structure

- **minimal.vim**: A minimal Neovim configuration for testing
- **basic_test.vim**: A simple test script that verifies the plugin loads correctly
- **config_test.vim**: Tests for the configuration validation and merging functionality
- **spec/**: (Future) Integration tests using the busted framework

## Running Tests

To run all tests:

```bash
make test
```

For more verbose output:

```bash
make test-debug
```

### Running Individual Tests

You can run specific test groups:

```bash
make test-basic  # Run only the basic functionality tests
make test-config  # Run only the configuration tests
```

## CI Integration

The tests are integrated with GitHub Actions CI, which runs tests against multiple Neovim versions:
- Neovim 0.8.0
- Neovim 0.9.0
- Neovim stable
- Neovim nightly

This ensures compatibility across different Neovim versions.

## Test Coverage

### Current Status

The test suite provides coverage for:

1. **Basic Functionality (`basic_test.vim`)**
   - Plugin loading
   - Module structure verification
   - Basic API availability

2. **Configuration (`config_test.vim`)**
   - Default configuration validation
   - User configuration validation
   - Configuration merging
   - Error handling

### Future Plans

We plan to expand the tests to include:

1. Integration tests for Laravel project detection
2. Mock tests for Artisan command execution
3. Test coverage for IDE Helper integration
4. Performance benchmarks for larger Laravel projects

## Test Dependencies

The basic and configuration tests only require Neovim.

For the future integration tests, we'll need:
- LuaFileSystem
- Busted
- Luassert
- Penlight

## Writing New Tests

When adding new functionality, please add corresponding tests following the same pattern as the existing tests:

1. Create a new test file in the test directory (e.g., `feature_test.vim`)
2. Add a new target to the Makefile
3. Update the CI workflow if needed

All tests should:
- Be self-contained and independent
- Provide clear pass/fail output
- Exit with an error code on failure