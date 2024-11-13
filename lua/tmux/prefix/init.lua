local file     = require("tmux.prefix.file")
local options  = require("tmux.configuration").options
local tmux     = require("tmux.wrapper.tmux")
local config   = require("tmux.configuration")

local M = {}

function M.setup()

	if tmux.file_exists(options.tmux.conf) == false then
		vim.notify("Does not exist " .. options.tmux.conf)
	end
	if tmux.file_exists(options.prefix.conf) == false then
		vim.notify("Does not exist " .. options.prefix.conf)
	end
	if tmux.file_exists(options.prefix.wincmd) == false then
		vim.notify("Does not exist " .. options.prefix.wincmd)
	end

	file.init()

	file.prefix_toggle()

end

return M
