" Basic test script for Laravel Helper
" Doesn't rely on busted, just checks that the plugin loads

echo "Basic test started"

" Check if we can load the plugin
lua << EOF
local ok, laravel_helper = pcall(require, 'laravel-helper')
if not ok then
  error("Failed to load laravel-helper: " .. tostring(laravel_helper))
end

-- Check version exists
if not laravel_helper.version then
  error("laravel_helper.version is missing")
end

-- Check config exists
if not laravel_helper.config then
  error("laravel_helper.config is missing")
end

-- Check key functions exist
if not laravel_helper.setup then
  error("laravel_helper.setup is missing")
end

print("All basic checks passed!")
EOF

echo "Basic test completed"