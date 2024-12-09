local function copy(target, preferences)
	if target == nil or preferences == nil then
		return
	end
	for index, _ in pairs(target) do
		if preferences[index] ~= nil and type(target[index]) == "table" and type(preferences[index]) == "table" then
			copy(target[index], preferences[index])
		elseif preferences[index] ~= nil and type(target[index]) == type(preferences[index]) then
			target[index] = preferences[index]
		end
	end
	for index, _ in pairs(preferences) do
		if preferences[index] ~= nil and target[index] == nil then
			target[index] = preferences[index]
		end
	end
end

local M = {
	--  Package manager corresponding file address for this plugin
	--  user_preferences = "",
	copy_sync = {
		--  Enables copy sync. by default, all registers are synchronized.
		--  to control which registers are synced, see the `sync_*` options.
		enable = true, --  false,

		--  Ignore specific tmux buffers e.g. buffer0 = true to ignore the
		--  first buffer or named_buffer_name = true to ignore a named tmux
		--  buffer with name named_buffer_name :)
		ignore_buffers = { empty = false },

		--  TMUX >= 3.2: all yanks (and deletes) will get redirected to system
		--  clipboard by tmux
		redirect_to_clipboard = false,

		--  Offset controls where register sync starts
		--  e.g. offset 2 lets registers 0 and 1 untouched
		register_offset = 0,

		--  Overwrites vim.g.clipboard to redirect * and + to the system
		--  clipboard using tmux. If your keep nvim syncing directly to the system clipboard without using tmux,
		--  disable this option!
		sync_clipboard = true,

		--  Synchronizes registers *, +, unnamed, and 0 till 9 with tmux buffers.
		sync_registers = true,

		--  Syncs deletes with tmux clipboard as well, it is adviced to
		--  do so. Nvim does not allow syncing registers 0 and 1 without
		--  overwriting the unnamed register. Thus, ddp would not be possible.
		sync_deletes = true,

		--  Syncs the unnamed register with the first buffer entry from tmux.
		sync_unnamed = true,
	},

	tmux = {
		--  conf = os.getenv("HOME") .. "/.tmux.conf",
		--  Reference implementation. Not essential to this plugin
		conf    = os.getenv("XDG_CONFIG_HOME") .. "/tmux/tmux.conf",
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
		prefix_bg_on_light  = "#d7d7ff",
		--  The background color value indicating entering copy-mode when nvim background is light
		normal_bg_on_light  = "colour003",
	},

	navigation = {
		conf    = os.getenv("XDG_CONFIG_HOME") .. "/tmux/navigation.conf",
		--  Cycles to opposite pane while navigating into the border
		cycle_navigation = true,

		--  Enables default keybindings (C-hjkl) for normal mode
		enable_default_keybindings = false,

		--  Prevents unzoom tmux when navigating beyond vim border
		persist_zoom = false,
	},

	resize = {
		conf    = os.getenv("XDG_CONFIG_HOME") .. "/tmux/resize.conf",
		--  Enables default keybindings (A-hjkl) for normal mode
		enable_default_keybindings = false,

		--  Sets resize steps for x axis
		resize_step_x = 5,

		--  Sets resize steps for y axis
		resize_step_y = 2,
	},

	logging = {
		--  log_address = vim.fn.stdpath("cache") .. "/tmux.nvim.log",
		--  file    = "warning",
			file    = "disabled",
		--  file    = "debug", --  For development
		--  notify  = "warning",
		--  notify  = "debug",
			notify  = "disabled",
	},
}

function M.set(options)
	if options == nil or options == "" then
		return
	end
	copy(M, options)
	return M
end

return M
