--  Merged logging into options for compatibility reasons with lazy.nvim
local M = {
    file    = "warning",
    notify  = "warning",
}

function M.set(result, options)
    if options == nil or options == "" then
        return
    end
	if result == nil or result == "" then
		result = {} --  local result = {}
    end
    for index, _ in pairs(options) do
        --  print("logging: " .. index, options[index])
        if require("tmux.log.severity").validate(options[index]) then
            --  print("logging: " .. index, options[index])
            result[index] = options[index]
        end
    end
	return result
end

return M
