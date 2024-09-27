local config    = require("tmux.configuration.logging")
local severity  = require("tmux.log.severity")

local M = {
    current = {},
    index   = 0,
}

function M.add(channel, func)
    if channel == nil or type(channel) ~= "string" then
        return
    end
    if func == nil or type(func) ~= "function" then
        return
    end
    M.current[channel] = func
end

function M.log(sev, message)
    for key, value in pairs(M.current) do
        -- if M.index < 10 then
        --     print("tmux.log.channels.init.log: config[" .. string.format("%-6s", key) .. "] = " .. config[key], sev)
        -- end
        if severity.check(config[key], sev) then
            -- if M.index < 10 then
            --     print("tmux.log.channels.init.log: " .. sev, message)
            -- end
            xpcall(function()
                value(sev, message)
            end, function(error)
                print("ERROR: Logging for channel " .. key .. " failed.", error)
            end)
        end
        M.index = M.index + 1
    end
end

return M
