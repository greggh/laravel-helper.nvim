.PHONY: test lint format docs clean

# Configuration
LUA_PATH ?= lua/
TEST_PATH ?= spec/
DOC_PATH ?= doc/

# Test command
test:
	@echo "Running tests..."
	@nvim --headless --noplugin -u test/minimal.vim -c "lua require('busted.runner')({ standalone = false, pattern = '_spec.lua$$', coverage = false })" -c "qa!" || \
	(echo "Tests failed"; exit 1)

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
	@echo "  make test    - Run tests"
	@echo "  make lint    - Lint Lua files"
	@echo "  make format  - Format Lua files with stylua"
	@echo "  make docs    - Generate documentation"
	@echo "  make clean   - Remove generated files"
	@echo "  make all     - Run lint, format, test, and docs"
