---@mod laravel-helper.commands Laravel Helper Commands
---@brief [[
--- This module provides the command interface for Laravel Helper plugin
--- It uses mega.cmdparse to create a structured command interface with
--- autocompletion and help documentation.
---@brief ]]

---@class LaravelHelperCommands
---@field setup_commands fun() Set up Laravel Helper commands

local M = {}

--- Creates the Laravel command structure using mega.cmdparse
---@return nil
function M.setup_commands()
    -- Require mega.cmdparse lazily - only when commands are actually set up
    local cmdparse = require("mega.cmdparse")
    local core = require("laravel-helper.core") -- Use existing core module

    -- Create the main Laravel command parser
    local parser = cmdparse.ParameterParser.new({
        name = "Laravel",
        help = "Laravel helper commands for Neovim"
    })

    -- Add subparsers for different command categories
    local subparsers = parser:add_subparsers({
        destination = "command",
        help = "Laravel helper commands"
    })

    -- Artisan subcommand
    local artisan = subparsers:add_parser({
        name = "artisan",
        help = "Run Laravel Artisan commands"
    })
    artisan:add_parameter({
        name = "args",
        nargs = "*",
        help = "Arguments to pass to Artisan"
    })
    artisan:set_execute(function(data)
        local args = data.namespace.args or {}
        local args_str = table.concat(args, " ")
        if args_str and args_str ~= "" then
            core.run_artisan_command(args_str)
        else
            core.run_artisan_command()
        end
    end)

    -- IDE Helper subcommands
    local ide_helper = subparsers:add_parser({
        name = "ide-helper",
        help = "Laravel IDE Helper commands"
    })
    local ide_helper_subparsers = ide_helper:add_subparsers({
        destination = "ide_helper_command",
        help = "IDE Helper operations"
    })

    -- IDE Helper generate command
    local generate = ide_helper_subparsers:add_parser({
        name = "generate",
        help = "Generate Laravel IDE Helper files"
    })
    generate:add_parameter({
        name = "--use-sail",
        action = "store_true",
        help = "Use Laravel Sail instead of PHP"
    })
    generate:set_execute(function(data)
        local use_sail = data.namespace["use-sail"] or false
        core.generate_ide_helper(true, use_sail)
    end)

    -- IDE Helper install command
    local install = ide_helper_subparsers:add_parser({
        name = "install",
        help = "Install Laravel IDE Helper package"
    })
    install:set_execute(function(_)
        core.install_ide_helper()
    end)

    -- IDE Helper debug command
    local debug = ide_helper_subparsers:add_parser({
        name = "debug",
        help = "Toggle debug mode for IDE Helper"
    })
    debug:set_execute(function(_)
        core.toggle_debug_mode()
        if core.debug_mode then
            core.debug_ide_helper_state()
        end
    end)

    -- Register the command
    cmdparse.create_user_command(parser)

    -- For backward compatibility, add the old command aliases that redirect to the new ones
    -- These will help users transition to the new command structure
    vim.api.nvim_create_user_command("LaravelGenerateIDEHelper", function(opts)
        local use_sail = opts.args == "sail"
        local cmd = use_sail and "Laravel ide-helper generate --use-sail" or "Laravel ide-helper generate"
        vim.api.nvim_command(cmd)
        vim.notify("Note: This command is deprecated. Please use '" .. cmd .. "' instead.", vim.log.levels.WARN)
    end, {
        desc = "Generate Laravel IDE Helper files (deprecated, use :Laravel ide-helper generate)",
        nargs = "?",
        complete = function() return { "php", "sail" } end
    })

    vim.api.nvim_create_user_command("LaravelInstallIDEHelper", function()
        vim.api.nvim_command("Laravel ide-helper install")
        vim.notify(
          "Note: This command is deprecated. Please use ':Laravel ide-helper install' instead.", 
          vim.log.levels.WARN
        )
    end, {
        desc = "Install Laravel IDE Helper package (deprecated, use :Laravel ide-helper install)"
    })

    vim.api.nvim_create_user_command("LaravelArtisan", function(opts)
        local args = opts.args
        local cmd = "Laravel artisan " .. args
        vim.api.nvim_command(cmd)
        vim.notify("Note: This command is deprecated. Please use '" .. cmd .. "' instead.", vim.log.levels.WARN)
    end, {
        desc = "Run Laravel Artisan command (deprecated, use :Laravel artisan)",
        nargs = "?",
        complete = "file"
    })

    vim.api.nvim_create_user_command("LaravelIDEHelperToggleDebug", function()
        vim.api.nvim_command("Laravel ide-helper debug")
        vim.notify(
          "Note: This command is deprecated. Please use ':Laravel ide-helper debug' instead.", 
          vim.log.levels.WARN
        )
    end, {
        desc = "Toggle Laravel IDE Helper debug mode (deprecated, use :Laravel ide-helper debug)"
    })
end

return M