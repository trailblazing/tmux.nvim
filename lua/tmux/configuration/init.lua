local log       = require("tmux.log")
local logging   = require("tmux.configuration.logging")
local options   = require("tmux.configuration.options")
local validate  = require("tmux.configuration.validate")
local tmux      = require("tmux.wrapper.tmux")

local M = {
    options = options,
    logging = logging,
}

function M.setup(opts, logs)
    -- print("tmux.configuration.init.setup:logs", vim.inspect(logs))
    M.logging.set(vim.tbl_deep_extend("force", {}, M.logging, logs or {}))
    -- print("tmux.configuration.init.setup:logging", vim.inspect(logging))
    log.debug("configuration injected: ", opts)
    -- print("tmux.configuration.init.setup:opts", vim.inspect(opts))
    M.options.set(vim.tbl_deep_extend("force", {}, M.options, opts or {}))
    -- print("tmux.configuration.init.setup:options", vim.inspect(options))

    if tmux.is_tmux then
        validate.options(tmux.version, M.options)
    end
end

return M
