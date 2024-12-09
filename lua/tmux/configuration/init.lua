local log       = require("tmux.log")
local logging   = require("tmux.configuration.logging")
local options   = require("tmux.configuration.options")
local validate  = require("tmux.configuration.validate")
local tmux      = require("tmux.wrapper.tmux")

local M = {
	options = options,
	--  logging     = logging,
}

--  Merged logging into options for compatibility reasons with lazy.nvim
function M.setup(opts) --  function M.setup(opts, logs)

    --  print("tmux.configuration.init.setup:logging", vim.inspect(M.options.logging))
    log.debug("logging configuration injected:\n", M.options.logging)
    --  M.logging.set(vim.tbl_deep_extend("force", {}, M.logging, opts.logging or {}))
    --  Done in upper init
    --  opts.logging = logging.set(vim.tbl_deep_extend("force", {}, opts.logging or {}))

    --  print("tmux.configuration.init.setup:logging", vim.inspect(M.options.logging))

    log.debug("options configuration injected:\n", opts)
    --  print("tmux.configuration.init.setup:opts", vim.inspect(opts))
    M.options.set(vim.tbl_deep_extend("force", {}, M.options, opts or {}))
    --  print("tmux.configuration.init.setup:options", vim.inspect(options))

    if tmux.is_tmux then
        validate.options(tmux.version, M.options)
    end
end

return M
