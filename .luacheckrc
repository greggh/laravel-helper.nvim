-- .luacheckrc for Laravel Helper plugin

std = {
  globals = {
    "vim",
    "table",
    "string",
    "math",
    "os",
  },
  read_globals = {
    "jit",
  },
}

-- Patterns for files to exclude
exclude_files = {
  ".luarocks/*",
  "lua/plenary/*",
  "tests/plenary/*",
}

-- Allow unused self arguments of methods
self = false

-- Don't report unused arguments/locals
unused_args = false
unused = false

-- Maximum line length
max_line_length = 120

-- Maximum cyclomatic complexity of functions
max_cyclomatic_complexity = 15
