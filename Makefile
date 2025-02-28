.PHONY: test test-debug lint format docs clean

# Configuration
LUA_PATH ?= lua/
TEST_PATH ?= spec/
DOC_PATH ?= doc/

# Test command
test:
	@echo "Running tests..."
	@nvim --headless --noplugin -u test/minimal.vim -c "lua print('Running basic tests')" -c "source test/basic_test.vim" -c "qa!"

# Debug test command - more verbose output
test-debug:
	@echo "Running tests in debug mode..."
	@echo "Path: $(PATH)"
	@echo "LUA_PATH: $(LUA_PATH)"
	@which nvim
	@nvim --version
	@echo "Testing with basic checks..."
	@nvim --headless --noplugin -u test/minimal.vim -c "lua print('Lua is working')" -c "source test/basic_test.vim" -c "qa!"

# Lint Lua files
lint:
	@echo "Linting Lua files..."
	@luacheck $(LUA_PATH)

# Format Lua files with stylua
format:
	@echo "Formatting Lua files..."
	@stylua $(LUA_PATH)

# Generate documentation
docs:
	@echo "Generating documentation..."
	@[ -x "$$(command -v ldoc)" ] && ldoc $(LUA_PATH) -d $(DOC_PATH) -c .ldoc.cfg || echo "ldoc not installed. Skipping documentation generation."

# Clean generated files
clean:
	@echo "Cleaning generated files..."
	@rm -rf $(DOC_PATH)luadoc

# Default target
all: lint format test docs

help:
	@echo "Laravel Helper development commands:"
	@echo "  make test       - Run tests"
	@echo "  make test-debug - Run tests with debug output"
	@echo "  make lint       - Lint Lua files"
	@echo "  make format     - Format Lua files with stylua"
	@echo "  make docs       - Generate documentation"
	@echo "  make clean      - Remove generated files"
	@echo "  make all        - Run lint, format, test, and docs"