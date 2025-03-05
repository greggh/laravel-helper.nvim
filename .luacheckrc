-- .luacheckrc for Laravel Helper plugin

std = {
  globals = {
    "vim",
    "table",
    "string",
    "math",
    "os",
    "io",
  },
  read_globals = {
    "jit",
    "require",
    "pcall",
    "type",
    "ipairs",
    "pairs",
    "tostring",
    "tonumber",
    "error",
    "assert",
    "_VERSION",
    "loadfile",
    "setfenv",
    "setmetatable",
    "getmetatable",
  },
}

-- Patterns for files to exclude
exclude_files = {
  ".luarocks/*",
  "lua/plenary/*",
  "tests/plenary/*",
}

-- Special configuration for scripts
files["scripts/**/*.lua"] = {
  globals = {
    "print", "arg",
  },
}

-- Special configuration for test files
files["tests/**/*.lua"] = {
  -- Allow common globals used in testing
  globals = {
    -- Common testing globals
    "describe", "it", "before_each", "after_each", "teardown", "pending", "spy", "stub", "mock",
    -- Lua standard utilities used in tests
    "print", "dofile",
    -- Test helpers
    "test", "expect",
    -- Global test state (allow modification)
    "_G", "package",
  },
  
  -- Define fields for assert from luassert
  read_globals = {
    assert = {
      fields = {
        "is_true", "is_false", "is_nil", "is_not_nil", "equals", 
        "same", "near", "matches", "has_error",
        "truthy", "falsy", "has", "has_no", "is_string", "is_number",
        "is_function", "is_table"
      }
    }
  },
  
  -- Allow modification of globals in test files
  allow_defined_top = true,
  
  -- Allow mutation of underscore globals in test files
  module = true,
  
  -- In tests, we're not concerned about these
  max_cyclomatic_complexity = false,
  
  -- For test files only, ignore unused arguments as they're often used for mock callbacks
  unused_args = false,
}

-- Special configuration for spec files
files["spec/**/*.lua"] = {
  -- Allow common globals used in testing
  globals = {
    -- Common busted globals
    "describe", "it", "before_each", "after_each", "teardown", "pending", "spy", "stub", "mock",
    -- Lua standard utilities used in tests
    "print", "dofile",
    -- Luassert
    "assert",
    -- Global state that specs might modify
    "_G", "vim", "package",
  },
  
  -- Allow modification of globals in spec files
  allow_defined_top = true,
  
  -- Disable module checking in specs
  module = false,
  
  -- In specs, we're not concerned about these
  max_cyclomatic_complexity = false,
  
  -- For specs, ignore unused arguments
  unused_args = false,
  
  -- Set all standard globals as writable in specs
  std = "+busted",
}

-- Allow unused self arguments of methods
self = false

-- Don't report unused arguments/locals
unused_args = false
unused = false

-- We don't ignore any warnings - all code style issues should be fixed
ignore = {
  -- No ignored warnings
}

-- Maximum line length
max_line_length = 120

-- Maximum cyclomatic complexity of functions
max_cyclomatic_complexity = 20

-- Override settings for specific files
files["lua/laravel-helper/core.lua"] = {
  max_cyclomatic_complexity = 60, -- This file has complex functions
}
