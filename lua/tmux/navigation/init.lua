local keymaps   = require("tmux.keymaps")
local navigate  = require("tmux.navigation.navigate")
local options   = require("tmux.configuration").options
local tmux      = require("tmux.wrapper.tmux")

local M = {}
function M.setup()
	if tmux.file_exists(options.navigation.conf) == false then
		vim.notify("Does not exist " .. options.navigation.conf)
	end
	if options.navigation.enable_default_keybindings then
		keymaps.register("n", {
			["<C-h>"]   = [[<cmd>lua require'tmux'.move_left()<cr>]],
			["<C-j>"]   = [[<cmd>lua require'tmux'.move_bottom()<cr>]],
			["<C-k>"]   = [[<cmd>lua require'tmux'.move_top()<cr>]],
			["<C-l>"]   = [[<cmd>lua require'tmux'.move_right()<cr>]],
			["<C-w>h"]  = [[<cmd>lua require'tmux'.move_left()<cr>]],
			["<C-w>j"]  = [[<cmd>lua require'tmux'.move_bottom()<cr>]],
			["<C-w>k"]  = [[<cmd>lua require'tmux'.move_top()<cr>]],
			["<C-w>l"]  = [[<cmd>lua require'tmux'.move_right()<cr>]],
		})
	end
end

function M.to_left()
	navigate.to("h")
end

function M.to_bottom()
	navigate.to("j")
end

function M.to_top()
	navigate.to("k")
end

function M.to_right()
	navigate.to("l")
end

return M
