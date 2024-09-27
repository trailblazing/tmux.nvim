local channels = require("tmux.log.channels")

local function convert(...)
    return require("tmux.log.convert").to_string(...)
end

local function log(severity, message, obj)
    local converted = convert(message)
    if obj then
        converted = converted .. convert(obj)
    end

    channels.log(severity, converted)
end

local M = {}
function M.setup()
    -- print('log setup performing')
    local log_address = require("tmux.log.channels.file").log_init()
    print('tmux.nvim log_address', log_address)
    channels.add("file", function(sev, msg)
        -- require('log').debug("tmux.log.channels.file will be required")
        require("tmux.log.channels.file").write(sev, msg)
    end)

    channels.add("notify", function(sev, msg)
        require("tmux.log.channels.notify").create().write(sev, msg)
    end)
end

function M.debug(message, obj)
    log("debug", message, obj)
end

function M.information(message, obj)
    log("information", message, obj)
end

function M.warning(message, obj)
    log("warning", message, obj)
end

function M.error(message, obj)
    log("error", message, obj)
end

return M
