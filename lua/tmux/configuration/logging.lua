local M = {
    file    = "warning",
    notify  = "warning",
}

function M.set(options)
    if options == nil or options == "" then
        return
    end
    for index, _ in pairs(options) do
        -- print("logging: " .. index, options[index])
        if require("tmux.log.severity").validate(options[index]) then
            -- print("logging: " .. index, options[index])
            M[index] = options[index]
        end
    end
end

return M
