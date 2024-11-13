local function copy(source, target)
	if source == nil or target == nil then
		return
	end
	for index, _ in pairs(source) do
		if target[index] ~= nil and type(source[index]) == "table" and type(target[index]) == "table" then
			copy(source[index], target[index])
		elseif target[index] ~= nil and type(source[index]) == type(target[index]) then
			source[index] = target[index]
		end
	end
	for index, _ in pairs(target) do
		if target[index] ~= nil and source[index] == nil then
			source[index] = target[index]
		end
	end
end

local M = {
	copy_sync = {
		--  enables copy sync. by default, all registers are synchronized.
		--  to control which registers are synced, see the `sync_*` options.
		enable = false,

		--  ignore specific tmux buffers e.g. buffer0 = true to ignore the
		--  first buffer or named_buffer_name = true to ignore a named tmux
		--  buffer with name named_buffer_name :)
		ignore_buffers = { empty = false },

		--  TMUX >= 3.2: all yanks (and deletes) will get redirected to system
		--  clipboard by tmux
		redirect_to_clipboard = false,

		--  offset controls where register sync starts
		--  e.g. offset 2 lets registers 0 and 1 untouched
		register_offset = 0,

		--  overwrites vim.g.clipboard to redirect * and + to the system
		--  clipboard using tmux. If your keep nvim syncing directly to the system clipboard without using tmux,
		--  disable this option!
		sync_clipboard = true,

		--  synchronizes registers *, +, unnamed, and 0 till 9 with tmux buffers.
		sync_registers = true,

		--  syncs deletes with tmux clipboard as well, it is adviced to
		--  do so. Nvim does not allow syncing registers 0 and 1 without
		--  overwriting the unnamed register. Thus, ddp would not be possible.
		sync_deletes = true,

		--  syncs the unnamed register with the first buffer entry from tmux.
		sync_unnamed = true,
	},

	tmux = {
		conf = os.getenv("HOME") .. "/.tmux.conf",
        header  = os.getenv("XDG_CONFIG_HOME") .. "/tmux/header.conf",
	},

	prefix = {
		conf    = os.getenv("XDG_CONFIG_HOME") .. "/tmux/prefix.conf",
		wincmd  = os.getenv("XDG_CONFIG_HOME") .. "/tmux/wincmd.conf",
		--  Because you want ot enable these keys before an editor's exists.
		--  So, do not do it here
		--  escape_key  = 'Escape',  --  Single key prefix trigger
		--  assist_key  = '',        --  Single key copy-mode trigger

		--  The background color value indicating entering prefix "mode" when vim background is dark
		prefix_background   = "#00d7d7",
		--  The background color value indicating entering copy-mode when nvim background is dark
		normal_background   = "colour003",
		--  The background color value indicating entering prefix "mode" when vim background is light
        prefix_bg_on_light  = "#d7d700",
		--  The background color value indicating entering copy-mode when nvim background is light
        normal_bg_on_light  = "colour003",
	},

	navigation = {
		conf    = os.getenv("XDG_CONFIG_HOME") .. "/tmux/navigation.conf",
		--  cycles to opposite pane while navigating into the border
		cycle_navigation = true,

		--  enables default keybindings (C-hjkl) for normal mode
		enable_default_keybindings = false,

		--  prevents unzoom tmux when navigating beyond vim border
		persist_zoom = false,
	},

	resize = {
		conf    = os.getenv("XDG_CONFIG_HOME") .. "/tmux/resize.conf",
		--  enables default keybindings (A-hjkl) for normal mode
		enable_default_keybindings = false,

		--  sets resize steps for x axis
		resize_step_x = 5,

		--  sets resize steps for y axis
		resize_step_y = 2,
	},

	logging = {
    	file    = "warning",
    	notify  = "warning",
	},
}

function M.set(options)
	if options == nil or options == "" then
		return
	end
	copy(M, options)
end

return M
