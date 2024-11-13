
local log_dir

local M = {}

function M.log_init()
    if log_dir == nil then
        log_dir = vim.fn.stdpath("cache") .. "/"
        os.execute("mkdir -p " .. log_dir)
    end

    M.log_address = log_dir .. "tmux.nvim.log"

    local logs = io.open(M.log_address, "w+a")
    logs:write("\n")
    logs:write(require("tmux.log.time").now())
    logs:write("\n")
    logs:flush()
    logs:close()

    return M.log_address
end

function M.write(sev, message)
    --  local logs = io.open(get_logdir() .. "tmux.nvim.log", "a")
    local logs = io.open(M.log_address, "a")
    --  logs:write(require("tmux.log.time").now() .. " " .. sev .. " ")
    logs:write(tostring(message) .. "\n")
    logs:flush()
    logs:close()
    --  io.close(logs)
end

return M
