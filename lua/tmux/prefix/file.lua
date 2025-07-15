local tmux    = require("tmux.wrapper.tmux")
local options = require("tmux.configuration.options")
local config  = require("tmux.configuration")
local map     = require("tmux.keymaps").map
local hl      = vim.api.nvim_set_hl
local log     = require("tmux.log")

--  tmux_key_enabled = false

--  local assist_on_normal_impl_alias_name = "" --  tmux_get_env("assist_on_normal_impl_alias_name")
local event                           = ''
local reload                          = ""
local prefix_background               = "" --  tmux_get_env("prefix_background")
local normal_background               = "" --  tmux_get_env("normal_background")
local prefix_bg_on_light              = "" --  tmux_get_env("prefix_bg_on_light")
local normal_bg_on_light              = "" --  tmux_get_env("normal_bg_on_light")
local fg_normal_original              = ""
local fg_normal_nc_original           = ""
local bg_normal_original              = ""
local bg_normal_nc_original           = ""
local prefix_key                      = "" --  tmux_get_env("prefix_key")
local normal_key                      = "" --  tmux_get_env("normal_key")
local escape_key                      = "" --  tmux_get_env("escape_key")
local assist_key                      = "" --  tmux_get_env("assist_key")
local default_background              = ""
local color_control_version           = 0
local assist_on_root_alias_name       = "" --  tmux_get_env("assist_on_root_alias_name")
local normal_on_root_nvim_alias_name  = "" --  tmux_get_env("normal_on_root_nvim_alias_name")
local assist_on_prefix_alias_name     = "" --  tmux_get_env("assist_on_prefix_alias_name")
local escape_on_root_alias_name       = "" --  tmux_get_env("escape_on_root_alias_name")
local escape_on_prefix_alias_name     = "" --  tmux_get_env("escape_on_prefix_alias_name")
local prefix_quit                     = "" --  tmux_get_env("prefix_quit")
local background_switched_by_plugin   = true
local one_stage_policy                = "" --  tmux_get_env("one_stage_policy")


--  From mode tigger key, key bindings on mode
--  bindings <- key <- mode
--  local prefix_prefix = "" --  tmux_runtime_bind(escape_key, "prefix",       true, true)
--  local prefix_root   = "" --  tmux_runtime_bind(escape_key, "root",         true, true)
--  local prefix_copy   = "" --  tmux_runtime_bind(escape_key, "copy-mode-vi", true, true) --  not in use currently
--  local normal_root   = "" --  tmux_runtime_bind(assist_key, "root",         true, true)


local function tmux_get_option(key, opts, default)
	--  local option_value = tmux.execute("show-options -gqv '" .. key .. "'")
	if opts == nil or opts == "" then
		opts = "-pqv"
	end
	local option_value = tmux.execute("show-options " .. opts .. " '@" .. key .. "'")
	if option_value == nil or option_value == "" then
		return default
	else
		return option_value
	end
end

local function tmux_get_env(key, opts, default)
	--  prefix_background="colour003"  # in tmux.conf
	if key == nil or  key == "" then
		if default == nil or default == "" then
			return ""
		else
			return default
		end
	end
	local key_value
	if opts ~= nil and  opts ~= "" then
		key_value = tmux.execute(
		"showenv " .. opts .. "'" .. key .. "' 2> /dev/null | awk -F = '{print $2}'"
		)
	else
		key_value = tmux.execute(
		'showenv -g "' .. key .. '" 2> /dev/null | awk -F = "{print \\$2}"'
		)
		if key_value == nil or key_value == "" then
			key_value = tmux.execute(
			"showenv -gh '" .. key .. "' 2> /dev/null | awk -F = '{print $2}'"
			)
		end
	end
	--  For %hidden key/value in tmux
	--  %hidden assist_key="Escape" # in tmux.conf
	if key_value == nil or key_value == "" then
		key_value = tmux.execute(
		'display -p "#{' .. key .. '}"'
		)
	end

	if key_value == nil then
		if default == nil or default == "" then
			key_value = ""
		else
			key_value = default
		end
	end

	--  print(key, key_value)
	return key_value
end

local function tmux_static_bind(key, mode, reuse_debug)
	local key_name = key .. '_' .. mode
	local key_value = tmux.execute(
		'display -p "#{' .. key .. '}"'
		)
	if key_value == nil then
		key_value = ""
	end
	if reuse_debug then
		print(key, key_value)
	end
	return key_value
end

local function tmux_runtime_bind(key, mode, reuse, debug)
	local cmd = "list-keys -T " .. mode .. " | awk -v key='" .. key .. "' '$4 == key {print}'"
	local value = tmux.execute(vim.api.nvim_replace_termcodes(cmd, true, true, true))
	if debug then
		print("capture result ".. "'" .. key .. "'[" .. mode .. "]", value)
	end
	if value ~= "" and reuse then
		value = value:gsub('%$' .. key, key)
		value = value:gsub(' ` ', [[ '`' ]])
		value = value:gsub(' '.. key .. ' ', [[ ']] .. key .. [[' ]])
		--  value = value:gsub("''", "'")
		value = value:gsub('"', "'")
		value = value:gsub('\\\\', "")
		value = value:gsub("\\'", '"')
		--  value = value:gsub("\"'$escape_key'\"", "'$escape_key'")
	else
		return value
	end
	if debug then
		print("capture rebuild ".. "'" .. key .. "'[" .. mode .. "]", value)
	end
	return value
end

local function tmux_set_env(key, opts, value)
	--  tmux.execute('setenv -gh normal_background "colour009"')
	--  tmux.execute(string.format("setenv -gh %s '%s'", "prefix_background", options.prefix.prefix_background))
	tmux.execute('setenv ' .. opts .. ' ' .. key .. ' "' .. value .. '"')
end

local function tmux_unset_env(key, opts)
	--  tmux.execute('setenv -ghu normal_background')
	tmux.execute('setenv ' .. opts .. ' -u ' .. key)
end

--  [Pass winID as a Lua Callback Argument for Autocommands](https://github.com/neovim/neovim/pull/26430)
--  [Add FloatNew and FloatClosed events](https://github.com/neovim/neovim/issues/26548)
--  [nvim: how to manually clear popups which do not clear themselves?](https://vi.stackexchange.com/questions/34654/nvim-how-to-manually-clear-popups-which-do-not-clear-themselves)
local function has_floating_window(tabnr)
	tabnr = tabnr or 0  --  by default, the current tabpage
	for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tabnr)) do
		local config = vim.api.nvim_win_get_config(win)
			--  return vim.api.nvim_win_get_config(win).relative ~= ""
			if config.relative ~= "" or config.zindex then return true end
		--  if relative ~= "" then
		--      tmux.execute(string.format("set-option -p -t '%s' '@%s' %s", tmux.get_tmux_pane(), 'is-float', 'on'))
		--      return true
		--  end
	end
	return false
end

local floating_close = function()
	tmux.execute("if -F '#{pane_in_mmode}' 'send-keys -X cancel'")
	if has_floating_window(0) then
		--  tmux.execute(string.format("set-option -p -t '%s' '@%s' %s", tmux.get_tmux_pane(), 'is-float', 'on'))
		--  tmux.execute("if -F '#{pane_in_mmode}' 'send-keys -X cancel' 'copy-mode'")
		--  "Invalid window id" if there are multiple pop-up windows
		for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
			--  for _, win in ipairs(vim.api.nvim_list_wins()) do
			if not vim.api.nvim_win_is_valid(win) then goto continue end
			local config = vim.api.nvim_win_get_config(win)
			if config.relative ~= "" or config.zindex then
				vim.api.nvim_win_close(win, true)
			end
			::continue::
		end

		local r, notify = pcall(require, "notify")
		if not r then notify = nil end
		if notify ~= nil then
			notify.dismiss() --  popup window
		end
		--  else
		--  tmux.execute("if -F '#{pane_in_mmode}' 'send-keys -X cancel'")
		print("Floating windows are closed")
		--  vim.print("Floating windows are closed")
	end
	tmux.execute(string.format("set-option -p -u -t '%s' '@%s'", tmux.get_tmux_pane(), 'is-float'))
end

local tmux_escape_key_cancel = function()
	--  if assist_key ~= '`' then
	if assist_key ~= escape_key and escape_key ~= ""  then
		--  if  ( escape_key ~= "" and tmux_runtime_bind(escape_key, 'prefix', false, false) ~= "" ) then
			--  If you do not quote "escape_key" (it might be a "`" --  backquote)
			--  sh: syntax error: EOF in backquote substitution
			tmux.execute("unbind -T prefix '" .. escape_key .. "'")
		--  end
		--  if  ( escape_key ~= "" and tmux_runtime_bind(escape_key, 'root', false, false) ~= "" ) then
			--  tmux.execute("set -g prefix None")
			tmux.execute("unbind -T root '"   .. escape_key .. "'")
		--  end
	end
	--  tmux.execute("set -p window-active-style fg=default,bg=terminal")

	tmux_unset_env("rescue", "-gh")
	--  tmux_key_enabled = false
end

local tmux_assist_key_cancel = function()
	if one_stage_policy ~= '1' then return false end
	--  tmux_escape_key_cancel()
	if assist_key ~= escape_key and assist_key ~= "" then
		--  if tmux_runtime_bind(assist_key, 'root', false, false) ~= "" then
		tmux.execute("unbind -T prefix '" .. assist_key .. "'")
		tmux.execute("unbind -T root '"   .. assist_key .. "'")
		--  end
	end
end

local tmux_assist_reenable = function(new_mode, old_mode)
	if one_stage_policy ~= '1' then return false end
	if assist_key == "" then return false end

	--  Unconditional override, because non-vim environment use the impl version
	--  if tmux_runtime_bind(assist_key, 'root',   false, false) == "" then
		tmux_set_env("rescue", "-gh", "true")
		tmux.execute(string.format("bind -T root '%s' %s", assist_key, assist_on_root_alias_name))
	--  tmux.execute(string.format("bind -T root '%s' run -C '%s'", assist_key, assist_on_root_alias_name))
		--  tmux.execute(string.format("bind -T root '%s' %s", assist_key, 'send-keys Escape Space N'))
	--  end
	if tmux_runtime_bind(assist_key, 'prefix', false, false) == "" then
		tmux_set_env("rescue", "-gh", "true")
		tmux.execute(string.format("bind -T prefix '%s' %s", assist_key, assist_on_prefix_alias_name))
	--  tmux.execute(string.format("bind -T prefix '%s' run -C '%s'", assist_key, assist_on_prefix_alias_name))
	end
	local assist_on_root_bind    = tmux_runtime_bind(assist_key, 'root', false, false)
	if assist_on_root_bind  == ""  then
		print("assist_on_root_bind recovery failed", "'" .. assist_on_root_bind .. "'")
		--  log.debug("assist_on_root_bind recovery failed" .. "'" .. assist_on_root_bind .. "'")
		vim.notify("assist_on_root_bind recovery failed" .. assist_on_root_bind)
	end
	local assist_on_prefix_bind  = tmux_runtime_bind(assist_key, 'prefix', false, false)
	if assist_on_prefix_bind  == ""  then
		print("assist_on_prefix_bind recovery failed", "'" .. assist_on_prefix_bind .. "'")
		--  log.debug("assist_on_prefix_bind recovery failed" .. "'" .. assist_on_prefix_bind .. "'")
		vim.notify("assist_on_prefix_bind recovery failed" .. assist_on_prefix_bind)
	end
	if assist_on_root_bind  == ""  or assist_on_prefix_bind  == ""  then
		reload()
		if
			tmux_runtime_bind(assist_key, 'root',   false, false)  == ""  or
			tmux_runtime_bind(assist_key, 'prefix', false, false)  == ""  then
			vim.notify("assist_key: " .. assist_key .. " bindings recovery failed")
		end
	end
end

local tmux_escape_reenable = function(new_mode, old_mode)
	if escape_key == "" then
		vim.print("escape_key: " .. escape_key)
		print("escape_key", escape_key)
		return false
	end
	--  if has_floating_window(0) then return end
	--  Deprecated. Hard to maintain
	--  if tmux.execute('show-options -gqv "@use-tmux-nvim"') == "on" then --  %hidden use_tmux_nvim_shell
	--  --  print('Using the tmux.nvim version of tmux binding')
	--  if tmux_runtime_bind(escape_key, 'prefix', false, false) == "" or tmux_runtime_bind(escape_key, 'root', false, false) == "" then
	--      os.execute('sh -c "' .. os.getenv('XDG_DATA_HOME') .. '/nvim/lazy/tmux.nvim/tmux.nvim.tmux ' .. '\"prefix_wincmd\" \"prefix_only\""')
	--  end
	--  return true
	--  end

	--  tmux.execute("set -g prefix '" .. escape_key .. "'")
	--  set-hook -g after-refresh-client[0] let it do the job ?

	--  Unconditional override, because non-vim environment use the impl version
	--  if tmux_runtime_bind(escape_key, 'root',   false, false) == "" then
	tmux_set_env("rescue", "-gh", "true")
	--  tmux.execute([[prefix_root_bind]])
	tmux.execute(string.format("bind -T root '%s' %s", escape_key, escape_on_root_alias_name)) --  out of date
	--  tmux.execute(string.format("bind -T root '%s' run -C '%s'", escape_key, escape_on_root_alias_name))
	--  end
	if tmux_runtime_bind(escape_key, 'prefix', false, false) == "" then

		--  tmux.execute('source-file "' .. options.prefix.conf .. '"')
		--  if tmux_get_option("is-insert", "-pqv", "") ~= "" then

		tmux.execute(string.format("set-option -p -u -t '%s' '@%s'", tmux.get_tmux_pane(), 'is-insert'))
		tmux_set_env("rescue", "-gh", "true")

		--  tmux.execute([[prefix_prefix_bind]])
		tmux.execute(string.format("bind -T prefix '%s' %s", escape_key, escape_on_prefix_alias_name))
		--  #{escape_on_prefix} might not exist if it is a parsing stage value
		--  tmux.execute(string.format("bind -T prefix '%s' run -C '%s'", escape_key, escape_on_prefix_alias_name))

		--  tmux.execute([[refresh-client]])
		--  tmux.execute([[send-keys Escape M-d]])       --  Dangerous
		--  tmux.execute([[send-keys Escape C-x]])       --  Dangerous
		--  tmux.execute(string.format("send-keys Escape C-x -t '%s'", tmux.get_tmux_pane()))
		--  tmux.execute([[send-keys Escape C-I Enter]]) --  Dangerous
		--  tmux.execute([[send-keys Escape C-I]])
	end

	local escape_on_root_bind    = tmux_runtime_bind(escape_key, 'root',   false, false)
	if escape_on_root_bind  == ""  then
		print("escape_on_root_bind recovery failed", "'" .. escape_on_root_bind .. "'")
		--  log.debug("escape_on_root_bind recovery failed" .. "'" .. escape_on_root_bind .. "'")
		vim.notify("escape_on_root_bind recovery failed" .. escape_on_root_bind)
	end
	local escape_on_prefix_bind  = tmux_runtime_bind(escape_key, 'prefix', false, false)
	if escape_on_prefix_bind  == ""  then
		print("escape_on_prefix_bind recovery failed", "'" .. escape_on_prefix_bind .. "'")
		--  log.debug("escape_on_prefix_bind recovery failed" .. "'" .. escape_on_prefix_bind .. "'")
		vim.notify("escape_on_prefix_bind recovery failed" .. escape_on_prefix_bind)
	end

	--  Tmux configuration might not have the static default values from the beginning
	--  Falling back if failed ? --  hard coded
	if  escape_on_root_bind == "" or
		escape_on_prefix_bind == "" then
		reload()
		if
			tmux_runtime_bind(escape_key, 'root',   false, false) == "" or
			tmux_runtime_bind(escape_key, 'prefix', false, false) == "" then
			vim.notify("escape_key: " .. escape_key .. " bindings recovery failed")
		end

		--  Does not work
		--  tmux.execute(string.format("bind '%s' %s", escape_key,
		--  vim.api.nvim_replace_termcodes(tmux_get_env("prefix_prefix"), true, true, true)))
		--  Fixed combinations look like this
		--  bind -T   root "$escape_key" $prefix_root
		--  bind -T prefix "$escape_key" $prefix_prefix
		--  bind -T   root "$assist_key" $normal_root

		--  Does not work
		--  #{prefix_root} might not exist if it is a parsing stage value
		--  Saving a copy and applying here will not succeed
		--  tmux.execute([[bind -n ']] .. escape_key .. [[' \"\$prefix_root\"]])
		--  #{prefix_prefix} might not exist if it is a parsing stage value
		--  tmux.execute(string.format("bind '%s' \"%s\"", escape_key, prefix_prefix))  --  no static settings available
		--  tmux.execute(string.format("bind -n '%s' \"%s\"", escape_key, prefix_root)) --  no static settings available
		--  tmux.execute(string.format("bind -n '%s' \"%s\"", assist_key, normal_root)) --  no static settings available

		--  Works but hard coded
		--  tmux.execute(string.format("bind '%s' if-shell true \" switch-client -T root ;  select-pane -P bg=terminal \"", escape_key))
		--  tmux.execute('bind -n "' .. escape_key .. '" switch-client -T prefix \\; select-pane -P bg=' .. options.prefix.prefix_background)

		--  tmux.execute(string.format("bind -n '%s' if-shell true \" switch-client -T prefix ;  select-pane -P bg=%s \"", escape_key, options.prefix.prefix_background))
		--  tmux.execute('bind -n "' .. assist_key .. '" copy-mode \\; select-pane -P bg=' .. options.prefix.normal_background)

		--  tmux.execute(string.format("bind -n '%s' if-shell true \" copy-mode ;  select-pane -P bg=%s \"", assist_key, options.prefix.normal_background))

	end

	--  Report the result to user
	--  tmux.execute("set -p window-active-style fg=default,bg=" .. prefix_background)
	--  tmux.execute("set -p window-active-style fg=default,bg=" .. normal_background)

	--  tmux_key_enabled = true
end

local function enable_conditional(new_mode, old_mode)
	if new_mode == old_mode then return false end
	--  Should I comment out the following filter for this condition?
	--  if not has_floating_window(0) then
		if
			string.find(new_mode, "n") ~= nil
			--  string.find(new_mode, "[rR]") == nil and
			--  string.find(new_mode, "i") == nil and
			--  and ( old_mode == nil or string.find(old_mode, "[ixsotrRvV\x16]") ~= nil)
			and string.find(new_mode, "[ixsotrRvV\x16]") == nil
			then
			tmux_escape_reenable(new_mode, old_mode)
			tmux_assist_reenable(new_mode, old_mode)
		end
	--  end

	--  if string.find(new_mode, "i") == 1 or string.find(new_mode, "[trcvV\x16]") ~= nil then
	if
		--  string.find(new_mode, "i") ~= nil or
		--  ( old_mode == nil or string.find(old_mode, "[ixsotrRvV\x16]") == nil ) and
		string.find(new_mode, "[ixsotrRvV\x16]") ~= nil
		then
		tmux_escape_key_cancel()
		tmux_assist_key_cancel()
	end
--  vim.cmd[[
--  " https://stackoverflow.com/questions/4110348/is-it-possible-to-disable-replace-mode-in-vim/4112482#4112482
--      if v:insertmode isnot# 'i'
--      endif
--  ]]
	--  Resolve float window Escape quit
	--  For float window
	--  if has_floating_window(0) then
	--      --  if string.find(new_mode, "n") ~= nil then
	--      --      tmux_escape_reenable(new_mode, old_mode)
	--      --      tmux_assist_reenable(new_mode, old_mode)
	--      --  end
	--      --  if string.find(new_mode, "i") ~= nil or string.find(new_mode, "[trcvV\x16]") ~= nil then
	--      if string.find(new_mode, "i") ~= nil or string.find(new_mode, "[trvV\x16]") ~= nil then
	--          --  it will trigger when input { or } to insert new line in normal mode  --  enter insert mode and out
	--          tmux_escape_key_cancel()
	--          tmux_assist_key_cancel()
	--      end
	--      --  return true
	--  end
end

local function color_hex(number)
	if number == nil or number == "" then return "" end
--  if type(number) == "string" then return number end
	if type(number) ~= "number" then return number end
	--  print("number", number)
	--  if (number):match("^%-?%+$") == nil then
	--  --  local name = ("" .. number .. ""):find("%D") and number
	--      if number ~= nil and  number ~= "" then return number end
	--  else
		return ('#%06x'):format(number)
	--  end
end

local function hl_hex(ns_id, hl_name)
	local hl = vim.api.nvim_get_hl(ns_id, { name = hl_name })
	if hl == nil or hl == "" then
	--  hl['fg'] = 'NONE'
	--  hl['bg'] = 'NONE'
	--  hl['sp'] = ''
	--  return hl
	return nil
	end
	for _, key in ipairs({'fg','bg','sp'}) do
		hl[key] = hl[key] ~= nil and color_hex(hl[key])
	end
	return hl
end

local function background_update(stage)
	print("stage", stage)
	local fg_normal, bg_normal
	local fg_normal_nc, bg_normal_nc
	local normal     = hl_hex(0, 'Normal')
	local normal_nc  = hl_hex(0, 'NormalNC')
	if normal ~= nil and normal.bg ~= nil then
		print("color_hex(normal.bg)", color_hex(normal.bg))
		if type(normal.bg) == "number" or type(normal.bg) == "string" then
			bg_normal     = normal.bg ~= nil    and color_hex(normal.bg) or 'NONE'
		--  bg_normal     = normal.bg ~= nil    and color_hex(normal.bg) or ''
		elseif type(normal.bg) == "boolean" then
			if normal.bg == false then bg_normal = 'NONE' end
		end
		if type(normal.fg) == "number" or type(normal.fg) == "string" then
			fg_normal     = normal.fg ~= nil    and color_hex(normal.fg) or 'NONE'
		elseif type(normal.fg) == "boolean" then
			if normal.fg == false then fg_normal = 'NONE' end
		end
	end
	if normal_nc ~= nil and normal_nc.bg ~= nil then
		print("color_hex(normal_nc.bg)", color_hex(normal_nc.bg))
		if type(normal_nc.bg) == "number" or type(normal_nc.bg) == "string" then
		--  bg_normal_nc  = normal_nc.bg ~= nil and color_hex(normal_nc.bg) or 'DarkGrey'
			bg_normal_nc  = normal_nc.bg ~= nil and color_hex(normal_nc.bg) or 'NONE'
		elseif type(normal_nc.bg) == "boolean" then
			if normal_nc.bg == false then bg_normal_nc = 'NONE' end
		end
		if type(normal_nc.fg) == "number" or type(normal_nc.fg) == "string" then
		--  bg_normal_nc  = normal_nc.bg ~= nil and color_hex(normal_nc.bg) or 'DarkGrey'
			bg_normal_nc  = normal_nc.fg ~= nil and color_hex(normal_nc.fg) or 'NONE'
		elseif type(normal_nc.fg) == "boolean" then
			if normal_nc.fg == false then fg_normal_nc = 'NONE' end
		end
	end

	if bg_normal ~= "" or fg_normal ~= "" then
	--  print("bg_normal", bg_normal)
	else
		vim.cmd[[
		let g:normal_background = synIDattr(hlID("Normal"), "bg")
		if g:normal_background ==? ""
			let g:normal_background = synIDattr(hlID("ActiveWindow"), "bg")
		endif
		if g:normal_background ==? ""
			let g:normal_background = 'NONE'
		endif
		let g:normal_foreground = synIDattr(hlID("Normal"), "fg")
		if g:normal_foreground ==? ""
			let g:normal_foreground = synIDattr(hlID("ActiveWindow"), "fg")
		endif
		if g:normal_foreground ==? ""
			let g:normal_foreground = 'NONE'
		endif
		]]
		bg_normal     = vim.g.normal_background
		fg_normal     = vim.g.normal_foreground
	end

	if bg_normal_nc ~= "" then
	--  print("bg_normal_nc", bg_normal_nc)
	else
		vim.cmd[[
		let g:normal_nc_background = synIDattr(hlID("NormalNC"), "bg")
		if g:normal_nc_background ==? ""
			let g:normal_nc_background = synIDattr(hlID("InactiveWindow"), "bg")
		endif
		if g:normal_nc_background ==? ""
			let g:normal_nc_background = 'NONE'
		endif
		let g:normal_nc_foreground = synIDattr(hlID("NormalNC"), "fg")
		if g:normal_nc_foreground ==? ""
			let g:normal_nc_foreground = synIDattr(hlID("InactiveWindow"), "fg")
		endif
		if g:normal_nc_foreground ==? ""
			let g:normal_nc_foreground = 'NONE'
		endif
		]]
		bg_normal_nc  = vim.g.normal_nc_background
		fg_normal_nc  = vim.g.normal_nc_foreground
	end

	if bg_normal == nil or  bg_normal == "" then
		print("----bg_normal forced to", bg_normal)
		bg_normal = 'NONE'
	end
	if fg_normal == nil or  fg_normal == "" then
		print("----fg_normal forced to", fg_normal)
		fg_normal = 'NONE'
	end

	if bg_normal_nc == nil or  bg_normal_nc == "" then
		print("----bg_normal_nc forced to", bg_normal_nc)
		bg_normal_nc = 'NONE'
	end
	if fg_normal_nc == nil or  fg_normal_nc == "" then
		print("----fg_normal_nc forced to", bg_normal_nc)
		fg_normal_nc = 'NONE'
	end

	if bg_normal_nc == bg_normal then
		vim.notify("Please correctly set the Normal and NormalNC colors")

		if vim.opt.background:get() == 'dark' then
			bg_normal     = 'NONE'
			bg_normal_nc  = 'DarkGrey'
		else
			bg_normal     = 'DarkGrey'
			bg_normal_nc  = 'NONE'
		end
	end
	hl(0, 'Normal',         { fg = fg_normal,  bg = bg_normal })
	hl(0, 'NormalNc',       { fg = fg_normal_nc,  bg = bg_normal_nc })

	hl(0, 'ActiveWindow',   { fg = fg_normal, bg = bg_normal, link = 'Normal', })
	hl(0, 'InactiveWindow', { fg = fg_normal_nc, bg = bg_normal_nc, link = 'NormalNC', })

	print("----fg_normal", fg_normal)
	print("----fg_normal_nc", fg_normal_nc)
	print("----bg_normal", bg_normal)
	print("----bg_normal_nc", bg_normal_nc)
	return fg_normal, fg_normal_nc, bg_normal, bg_normal_nc
end

local reverse = function(color_control_version, reverse_targert)
	local bg_current = vim.opt_local.background:get()
	if color_control_version == 0 then
		--  Version 0
		if bg_current == nil or bg_current == "" then
			bg_current = vim.opt.background:get()
		end
	--  else
		--  Version 1
		--  local normal = hl_hex(0, 'Normal')
		--  local bg_current = normal.bg ~= nil and color_hex(normal.bg) or 'DarkGrey'
		--  _, _, bg_current, _ = background_update('<Leader>V')
	end
	--  if
	--      --  --  tmux_get_env('default_background') ~= vim.opt_local.background:get() and
	--      --  --  bg_current ~= bg_normal_original
	--  --  default_background ~= bg_current
	--      default_background == bg_current
	--      then
	--          return false
	--      end

	--  true then
	--  else
	if color_control_version == 0 then
		--  Version 0
		local bg_reverse = 'dark'
		if reverse_targert == "current_background" then
			if vim.opt_local.background:get() == 'dark' then
		--  if default_background == 'dark' then
		--  if bg_current == 'dark' then
				bg_reverse = 'light'
			end
		elseif reverse_targert == "default_background" then
			if default_background == 'dark' then
				bg_reverse = 'light'
			end
		elseif reverse_targert == "" then
			if bg_current == 'dark' then
				bg_reverse = 'light'
			end
		end
		background_switched_by_plugin = true
		--  Version 0
		vim.api.nvim_set_option_value('background', bg_reverse, { scope = 'local' })
		--  Version 0
		tmux_set_env("current_background", "-gh", bg_reverse)
		background_switched_by_plugin = false
	else
		--  Version 1
		--  hl(0, 'Normal',         { fg = 'NONE',  bg = bg_normal_original, })
		hl(0, 'Normal',         { fg = fg_normal_original,  bg = 'NONE', })
		hl(0, 'NormalNC',       { fg = fg_normal_nc_original,  bg = bg_normal_nc_original, })
		--  hl(0, 'ActiveWindow',   { fg = 'NONE',  bg = bg_normal_original, })
		--  hl(0, 'InactiveWindow', { fg = 'NONE',  bg = bg_normal_nc_original, })
		hl(0, 'ActiveWindow',   { fg = fg_normal_original,  bg = 'NONE', })
		hl(0, 'InactiveWindow', { fg = fg_normal_nc_original,  bg = bg_normal_nc_original, })
		vim.opt.winhighlight = 'Normal:ActiveWindow,NormalNC:InactiveWindow'
		--  vim.opt.winhighlight = 'Normal:InactiveWindow,NormalNC:ActiveWindow'

		--  --  vim.opt.winhighlight = string.formt('Normal:%s,NormalNC:%s', bg_normal_nc_original, bg_normal_original)

		--  _, _, bg_current, _ = background_update('<Leader>V')
		_, _, bg_current, _ = background_update('<M-' .. prefix_key .. '>')

		--  --  vim.opt_local.background = 'dark'
		--  --  local hl = vim.api.nvim_set_hl
		--  --  tmux_unset_env("current_background", "-gh")

		--  Version 1
		--  Tell tmux the current background is reversed
		--  tmux_set_env("current_background", "-gh", vim.api.nvim_replace_termcodes(bg_normal_nc_original, true, true, true))
		--  print("<Leader>V: bg_current", bg_current)
		--  print("type(bg_current)", type(bg_current))
		tmux_set_env("current_background", "-gh", vim.api.nvim_replace_termcodes(bg_current, true, true, true))

		--  --  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('k', true, false, true), 'm', true)
	end
	--  end
	--  vim.cmd[[redraw!]]
end

local restore = function(color_control_version)
	local bg_current = vim.opt_local.background:get()
	if color_control_version == 0 then
		--  Version 0
		if bg_current == nil or bg_current == "" then
			bg_current = vim.opt.background:get()
		end
	else
		--  Version 1
		--  --  local normal_nc = hl_hex(0, 'NormalNC')
		--  --  bg_normal_nc_original  = normal_nc.bg ~= nil and color_hex(normal_nc.bg) or 'NONE'
		--  local normal = hl_hex(0, 'Normal')
		--  local bg_current = normal.bg ~= nil and color_hex(normal.bg) or 'DarkGrey'
		--  _, _, bg_current, _ = background_update('<Leader>S')
	end
	--  if
	--  --  --  tmux_get_env('default_background') == vim.opt_local.background:get() and
	--  --  default_background == bg_current
	--      default_background ~= bg_current
	--  --  --  bg_current == bg_normal_original
	--      then
	--          return false
	--      end
	--  else
	if color_control_version == 0 then
		background_switched_by_plugin = true
		--  Version 0
		vim.api.nvim_set_option_value('background', default_background, { scope = 'local' })
		--  Version 0
		tmux_set_env("current_background", "-gh", default_background)
		background_switched_by_plugin = false
	else
		--  Version 1
		hl(0, 'Normal',         { fg = fg_normal_original,  bg = bg_normal_original, })
		hl(0, 'NormalNc',       { fg = fg_normal_nc_original,  bg = bg_normal_nc_original, })
		hl(0, 'ActiveWindow',   { fg = fg_normal_original,  bg = bg_normal_original, })
		hl(0, 'InactiveWindow', { fg = fg_normal_nc_original,  bg = bg_normal_nc_original, })
		vim.opt.winhighlight = 'Normal:ActiveWindow,NormalNC:InactiveWindow'

		--  --  vim.opt.winhighlight = 'Normal:InactiveWindow,NormalNC:ActiveWindow'
		--  --  vim.opt.winhighlight = string.format('Normal:%s,NormalNC:%s', bg_normal_original, bg_normal_nc_original)

		--  _, _, bg_current, _ = background_update('<Leader>S')
		_, _, bg_current, _ = background_update('<M-C>')

		--  --  vim.opt_local.background = 'light'
		--  --  local hl = vim.api.nvim_set_hl
		--  --  hl(0, 'Normal', { fg = 'Black', bg = 'Grey' })
		--  --  tmux_set_env("current_background", "-gh", "on")
		--
		--  Version 1
		--  Tell tmux the current background is restored
		--  tmux_set_env("current_background", "-gh", vim.api.nvim_replace_termcodes(bg_normal_original, true, true, true))
		--  print("<Leader>S: bg_current", bg_current)
		--  print("type(bg_current)", type(bg_current))
		--  local test = vim.api.nvim_replace_termcodes(bg_current, true, true, true)
		tmux_set_env("current_background", "-gh", vim.api.nvim_replace_termcodes(bg_current, true, true, true))
		--
		--  --  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('k', true, false, true), 'm', true)
	end
	--  end
	--  vim.cmd[[redraw!]]
end

local function init(event)

	prefix_background   = tmux_get_env("prefix_background")
	normal_background   = tmux_get_env("normal_background")
	prefix_bg_on_light  = tmux_get_env("prefix_bg_on_light")
	normal_bg_on_light  = tmux_get_env("normal_bg_on_light")
	prefix_key          = tmux_get_env("prefix_key")
	normal_key          = tmux_get_env("normal_key")
	escape_key          = tmux_get_env("escape_key")
	assist_key          = tmux_get_env("assist_key")

	color_control_version = 0 --  How to determine editor triggered background chaanges?
	--  color_control_version = 1

--  assist_on_normal_impl_alias_name  = tmux_get_env("assist_on_normal_impl_alias_name")
	assist_on_root_alias_name       = tmux_get_env("assist_on_root_alias_name")
	normal_on_root_nvim_alias_name  = tmux_get_env("normal_on_root_nvim_alias_name")
	assist_on_prefix_alias_name     = tmux_get_env("assist_on_prefix_alias_name")
	escape_on_root_alias_name       = tmux_get_env("escape_on_root_alias_name")
	escape_on_prefix_alias_name     = tmux_get_env("escape_on_prefix_alias_name")
	prefix_quit                     = tmux_get_env("prefix_quit")
	one_stage_policy                = tmux_get_env("one_stage_policy")

	--  From mode tigger key, key bindings on mode
	--  bindings <- key <- mode
	--  if escape_key ~= "" then
	--      prefix_prefix = tmux_runtime_bind(escape_key, "prefix",       true, true)
	--      prefix_root   = tmux_runtime_bind(escape_key, "root",         true, true)
	--      prefix_copy   = tmux_runtime_bind(escape_key, "copy-mode-vi", true, true) --  not in use currently
	--  end
	--  if assist_key ~= "" then
	--      normal_root   = tmux_runtime_bind(assist_key, "root",         true, true)
	--  end

	if options.prefix.prefix_background ~= prefix_background then
	--  if options.prefix.prefix_background ~= nil and options.prefix.prefix_background ~= "" then
		--  print("options.prefix.prefix_background", options.prefix.prefix_background)
		tmux_unset_env("prefix_background", "-gh")
		--  tmux setenv -g prefix_background 'colour003'
		tmux_set_env("prefix_background", "-gh", options.prefix.prefix_background)
		--  local prefix_background = tmux.execute(string.format("showenv -gh '%s' 2> /dev/null | awk -F = '$2 = $2 {print $2}'", "prefix_background"))
		--  if prefix_background ~= "" then
		--      print("prefix_background", prefix_background)
		--  end
	--  end
	end
	if options.prefix.normal_background ~= normal_background then
		tmux_unset_env("normal_background", "-gh")
		tmux_set_env("normal_background", "-gh", options.prefix.normal_background)
	end

	if options.prefix.prefix_bg_on_light ~= prefix_bg_on_light then
		tmux_unset_env("prefix_bg_on_light", "-gh")
		tmux_set_env("prefix_bg_on_light", "-gh", options.prefix.prefix_bg_on_light)
	end

	if options.prefix.normal_bg_on_light ~= normal_bg_on_light then
		tmux_unset_env("normal_bg_on_light", "-gh")
		tmux_set_env("normal_bg_on_light", "-gh", options.prefix.normal_bg_on_light)
	end

	if event ~= 'reload' then --  otherwise the background will not return to user default after reloading
		if color_control_version == 0 then
		--  --  if vim.opt_local.background == "light" then
		--  --      tmux_set_env("default_background", "-gh", "on")
		--  Version 0
			default_background = vim.opt.background:get()
		else
		--  Version 1

			fg_normal_original, fg_normal_nc_original, bg_normal_original, bg_normal_nc_original = background_update('init')
			default_background = bg_normal_original
		--  --  else
		--  --      tmux_unset_env("default_background", "-gh")
		--  --  end
		end

		print("background_switched_by_plugin", background_switched_by_plugin)
		--  Tell tmux the current user prefiered default_background
		tmux_set_env("default_background", "-gh", default_background)
	end

	--  local restore_key = "RESTORE"
	local restore_key = "F"
	--  map('n', 'SETLIGHT',
	--  map('n', '<M-S>', function() restore(0) end, { noremap = true })
	map('n', '<M-' .. restore_key .. '>', function() restore(0) end, { noremap = true })
	--  map('n', '<Leader>S', function() restore(0) end, { noremap = true })
	--  map('n', '<Leader>RESTORE', function() restore(0) end, { noremap = true })
	local reverse_key = "K"   --  = "REVERSE"
	--  map('n', 'SETDARK',
	--  if assist_key ~= "" then
	--  	reverse_key = assist_key   --  this is a bug, alt-assist_key triggers assist_key itself
	--  else
	--  	reverse_key = "K"   --  reverse_key = "REVERSE"
	--  end
	--  map('n', 'SETDARK',
	map('n', '<M-' .. reverse_key .. '>', function() reverse(0, "default_background") end, { noremap = true })
	--  map('n', '<Leader>V', function() reverse(0) end, { noremap = true })
	--  map('n', '<Leader>REVERSE', function() reverse(0) end, { noremap = true })

	--  Deprecated
	--  map('n', 'SETQUIT',
	--  function()
	--      print("stage", 'SETQUIT')
	--  --  tmux.execute(string.format("%s", 'send-keys -X cancel'))
	--  --  tmux.execute(string.format("if-shell true {\n%s\n}", tmux.execute("display -p \"#{assist_on_normal_impl}\"")))
	--      tmux.execute(string.format("%s", assist_on_normal_impl_alias_name))
	--  --  restore(0)
	--  end, { noremap = true })
	local normal_on_root_nvim_key
	if normal_key ~= "" then
		normal_on_root_nvim_key = normal_key
	else
		normal_on_root_nvim_key = "Escape"
	end
	--  The reason you need this following mapping is that -- if without it, the background won't change during copy-mode launching operation
	--  map('n', '<Leader>N',
	map('n', '<M-' .. normal_on_root_nvim_key .. '>',
	function()
		--  print("stage", '<Leader>N')
		print("stage", '<M-' .. normal_on_root_nvim_key .. '>')
		--  Might came from two sources
	--  print("assist_on_root", assist_on_root_alias_name)
	--  print("escape_on_root", escape_on_root_alias_name)
		--  reverse(0, "") --  key operation
		    restore(0)
	--  vim.o.background = 'dark'


	--      tmux.execute(string.format("%s", 'switch-client -T prefix'))
	--      --  restore(0)
	--      tmux.execute(string.format("%s", 'switch-client -T root'))
	--  --  tmux.execute(string.format("%s", 'switch-client -T root'))
	--      --  tmux.execute(string.format("%s", 'select-pane -P bg=terminal'))
	--  --  tmux.execute(string.format("select-pane -t '%s' -P bg=terminal", tmux.get_tmux_pane()))
	--      tmux.execute(string.format("%s", 'set-window-option -g mode-style "fg=default,bg=#{normal_bg_on_light}"'))
	--      tmux.execute(string.format("%s", 'copy-mode'))
	--  --  tmux.execute(string.format("%s", 'send-keys -X cancel'))
	--          reverse(0)

	--      tmux.execute(string.format("%s", 'switch-client -T prefix'))
	--      --  restore(0)
	--      tmux.execute(string.format("%s", 'switch-client -T root'))
		print("normal_on_root_nvim_alias_name", normal_on_root_nvim_alias_name)
	--  Works
		tmux.execute(string.format("%s", normal_on_root_nvim_alias_name))
	--  Works --  deprecated
	--  tmux.execute(string.format("run -C '%s'", "normal_on_root_nvim_slot"))
	--  tmux.execute(string.format("%s", "normal_on_root_nvim_slot"))
	--  tmux.execute(string.format("%s", 'copy-mode'))
	end, { noremap = true })

	map('n', '<M-Z>', function() reload() end, { noremap = true })

	--  Modifying escape_key and assist_key is not a trivial task
	--  Do it in tmux configuration files is a better choice
	--  if options.prefix.escape_key ~= escape_key then
	--      tmux_set_env("escape_key", "-gh", options.prefix.escape_key)
	--  end
	--  if options.prefix.assist_key ~= assist_key then
	--      tmux_set_env("assist_key", "-gh", options.prefix.assist_key)
	--  endRK
	--
end

local function prefix_toggle()

	print("escape_key", escape_key)
	print("assist_key", assist_key)

	vim.api.nvim_create_autocmd({ "OptionSet" }, {
		group = vim.api.nvim_create_augroup("tmux_nvim_report_is_light", { clear = true }),
		pattern = { "background" },
		callback = function()
			if background_switched_by_plugin then return false end
			print("background_switched_by_plugin", background_switched_by_plugin)
			--  --  if vim.opt_local.background == 'light' then
			--  --  tmux_set_env("current_background", "-gh", "on")
			--  --  tmux_set_env("current_background", "-gh", vim.opt_local.background:get())
			--  --  else
			--  --      tmux_unset_env("current_background", "-gh")
			--  --  end

			--  local normal = hl_hex(0, 'Normal')
			--  normal_bg     = normal.bg ~= nil and color_hex(normal.bg) or bg_normal_original
			--  tmux_set_env("current_background", "-gh", normal_bg)
			if color_control_version == 1 then
				fg_normal_original, fg_normal_nc_original, bg_normal_original, bg_normal_nc_original = background_update("OptionSet")
				default_background = bg_normal_original
			else
				default_background = vim.opt.background:get()
			end
			--  Tell tmux the current user prefiered default_background
			tmux_set_env("default_background", "-gh", default_background)
		end,
	})

	vim.api.nvim_create_autocmd({ "ModeChanged", "InsertChange" }, {
		group = vim.api.nvim_create_augroup("tmux_prefix_modechanged", { clear = true }),
		pattern = { "*" },
		callback = function(prev)
			--  vim.print(vim.inspect(vim.v.event))
			print("vim.v.event", vim.inspect(vim.v.event))
			local old_mode = ""
			vim.defer_fn(function()
				if
					vim.v.event ~= nil and
					type(vim.v.event) == "table" and
					vim.v.event.old_mode ~= nil
					then
					old_mode = vim.v.event.old_mode
				end
				local new_mode = vim.api.nvim_get_mode().mode
				--  if new_mode ~= old_mode then
				enable_conditional(new_mode, old_mode)
				--  end
			end, 10)
		end
	})

	--  local nvim_report = vim.api.nvim_create_augroup("tmux_nvim_report", { clear = true }),

	vim.api.nvim_create_autocmd({ "WinEnter" }, { --  "WinNew",
		group = vim.api.nvim_create_augroup("tmux_nvim_report_winenter", { clear = true }),
		pattern = { "*" },
		callback = function(args)
			if has_floating_window(0) then
				tmux.execute(string.format("set-option -p -t '%s' '@%s' %s", tmux.get_tmux_pane(), 'is-float', 'on'))
			--  else
			--      tmux.execute(string.format("set-option -p -u -t '%s' '@%s'", tmux.get_tmux_pane(), 'is-float'))
			end
		end,
	})

	vim.api.nvim_create_autocmd({ "WinClosed", "WinLeave" }, {
		group = vim.api.nvim_create_augroup("tmux_nvim_report_winleave", { clear = true }),
		pattern = { "*" },
		callback = function(args)
			if not has_floating_window(0) then
				tmux.execute(string.format("set-option -p -u -t '%s' '@%s'", tmux.get_tmux_pane(), 'is-float'))
			--  else
			--      tmux.execute(string.format("set-option -p -t '%s' '@%s' %s", tmux.get_tmux_pane(), 'is-float', 'on'))
			end
			if tmux_get_option("is-insert", "-pqv", "") ~= "" then
				tmux.execute(string.format("set-option -p -u -t '%s' '@%s'", tmux.get_tmux_pane(), 'is-insert'))
			end
		end,
	})

	vim.api.nvim_create_autocmd({ "InsertLeave" }, {
		group = vim.api.nvim_create_augroup("tmux_nvim_report_insertleave", { clear = true }),
		pattern = { "*" },
		callback = function(args)
			if tmux_get_option("is-insert", "-pqv", "") ~= "" then
				--  if not has_floating_window(0) then
				tmux.execute(string.format("set-option -p -u -t '%s' '@%s'", tmux.get_tmux_pane(), 'is-insert'))
				--  end
			end
		end,
	})

	vim.api.nvim_create_autocmd({ "CmdlineLeave" }, {
		group = vim.api.nvim_create_augroup("tmux_nvim_report_cmdlineleave", { clear = true }),
		pattern = { "*" },
		callback = function(args)
			if tmux_get_option("is-cmd", "-pqv", "") ~= "" then
				tmux.execute(string.format("set-option -p -u -t '%s' '@%s'", tmux.get_tmux_pane(), 'is-cmd'))
			end
			if tmux_get_option("is-insert", "-pqv", "") ~= "" then
			--      if not has_floating_window(0) then
				tmux.execute(string.format("set-option -p -u -t '%s' '@%s'", tmux.get_tmux_pane(), 'is-insert'))
			--      end
			end
		end,
	})

	vim.api.nvim_create_autocmd({ "InsertEnter", "InsertCharPre", "InsertChange" }, {
		group = vim.api.nvim_create_augroup("tmux_nvim_report_insertenter", { clear = true }),
		pattern = { "*" },
		callback = function(args)
			--  if tmux_get_option("is-insert", "-pqv", "") == "" then
				tmux.execute(string.format("set-option -p -t '%s' '@%s' %s", tmux.get_tmux_pane(), 'is-insert', 'on'))
			--  end
		end,
	})

	vim.api.nvim_create_autocmd({ "CmdlineEnter" }, {
		group = vim.api.nvim_create_augroup("tmux_nvim_report_cmdlineenter", { clear = true }),
		pattern = { "*" },
		callback = function(args)
			tmux.execute(string.format("set-option -p -t '%s' '@%s' %s", tmux.get_tmux_pane(), 'is-cmd', 'on'))
			if tmux_get_option("is-insert", "-pqv", "") == "" then
				tmux.execute(string.format("set-option -p -t '%s' '@%s' %s", tmux.get_tmux_pane(), 'is-insert', 'on'))
			end
		end,
	})

	--  local clutch = vim.api.nvim_create_augroup("tmux_prefix_toggle", { clear = true }),

	vim.api.nvim_create_autocmd({ "InsertLeave", "CmdlineLeave", "VimEnter" }, {
		group = vim.api.nvim_create_augroup("tmux_prefix_insertleave", { clear = true }),
		pattern = { "*" },
		callback = function(args)
			--  If do not filter floating windows here, the earlier enabling will transfer to prefix_enter's
			--  send-keys Escape C-c and enter the prefix mode
			local new_mode = vim.api.nvim_get_mode().mode
			--  enable_conditional(new_mode, old_mode)
			--  if not has_floating_window(0) then
			--      print("InsertLeave", "check/recover key bindings")
			--      local new_mode = vim.api.nvim_get_mode().mode
					tmux_escape_reenable(new_mode, "")
					tmux_assist_reenable(new_mode, "")
			--  else
			--      print("InsertLeave", "check/disable key bindings")
			--      tmux_escape_key_cancel()
			--      tmux_assist_key_cancel()
			--  end
		end,
	})

	vim.api.nvim_create_autocmd({ "FocusLost" }, {
		group = vim.api.nvim_create_augroup("tmux_prefix_focuslost", { clear = true }),
		pattern = { "*" },
		callback = function(args)
		--  tmux_escape_key_cancel()
			tmux_assist_key_cancel()
		end,
	})

	vim.api.nvim_create_autocmd({ "InsertEnter", "CmdlineEnter", "InsertCharPre", "InsertChange" }, {
		group = vim.api.nvim_create_augroup("tmux_prefix_insertenter", { clear = true }),
		pattern = { "*" },
		callback = function(args)
			tmux_escape_key_cancel()
			tmux_assist_key_cancel()
		end,
	})

	vim.api.nvim_create_autocmd({ "VimLeave", 'VimSuspend' }, { --  , "CmdlineEnter", "VimLeavePre"
		group = vim.api.nvim_create_augroup("tmux_prefix_vimleave", { clear = true }),
		pattern = { "*" },
		callback = function(args)
			--  if ( assist_key ~= "" and tmux_runtime_bind(assist_key, 'root', false, false) == "" ) or escape_key == "Escape" then
			--  if assist_key ~= "" and
			--      tmux_runtime_bind(assist_key, 'root',   false, false) == "" and
			--      tmux_runtime_bind(assist_key, 'prefix', false, false) == "" then
			--      --  tmux.execute('source-file "' .. options.prefix.conf .. '"')
			--      --  if tmux_get_option("is-insert", "-pqv", "") ~= "" then
			--          tmux.execute(string.format("set-option -p -u -t '%s' '@%s'", tmux.get_tmux_pane(), 'is-insert'))
			--      --  end
			--  end

			local new_mode = vim.api.nvim_get_mode().mode
			tmux_escape_reenable(new_mode, "") --  Available between terminal ans editor

			--  tmux_set_env("rescue", "-gh", "true")
			--  tmux.execute(string.format("bind -T prefix '%s' %s", escape_key, escape_on_prefix_alias_name))
			--  tmux.execute(string.format("bind -T root '%s' %s",   escape_key, normal_on_root_nvim_alias_name))
			tmux_assist_key_cancel() --  assist_key should not interfere with terminal input functions

			tmux.execute(string.format("set-option -p -u -t '%s' '@%s'", tmux.get_tmux_pane(), 'is-insert'))
			tmux.execute(string.format("set-option -p -u -t '%s' '@%s'", tmux.get_tmux_pane(), 'is-float'))
			tmux.execute(string.format("set-option -p -u -t '%s' '@%s'", tmux.get_tmux_pane(), 'is-cmd'))
		end,
	})

	vim.api.nvim_create_autocmd({ "WinClosed", "WinLeave", "TextChanged" }, { --  "WinResized", "WinEnter", "BufHidden"
		group = vim.api.nvim_create_augroup("tmux_prefix_winclosed", { clear = true }),
		pattern = { "*" },
		callback = function(args)
			--  Telescope float windows can't be judged by has_floating_window()
			--  local active_pane_id = tmux.execute("display -p '#{pane_id}'")
			--  print("active_pane_id", active_pane_id)
			--  local active_pane_is_vim = tmux_get_option("is-vim", string.format("%s", [[-t "#{pane_id}" -pqv]]), "") --  Never works
			--  local active_pane_is_vim = tmux_get_option("is-vim", "-t " .. active_pane_id .. " -pqv", "")

			if  --  true
			--  active_pane_is_vim == 'on'
				tmux_get_option("is-vim", "-t " .. tmux.execute("display -p '#{pane_id}'") .. " -pqv", "") == 'on'
			--  tmux_get_option("is-vim", "-t '#{pane_id}' -pqv", "") == 'on' --  Never works
			--  or not has_floating_window(0)
				and not has_floating_window(0)
				and tmux_get_option("is-insert", "-pqv", "") ~= 'on'
			then
				--  print("WinClosed/WinLeave on " .. tmux.execute("display -p '#{pane_id}'"), "check/recover key bindings")

				--  print("active_pane_is_vim", active_pane_is_vim)

			--  print("vim.v.event", serialize(vim.v.event))
			--  '\' key open telescope or :ls, then Esc to quit to normal mode, then you need the following codes
			--  to recover the escape_key and assist_key
			--  But if no #{pane_id} filter, non-vim panes will be polluted
				--  local client_key_table = tmux_get_env("client_key_table")
				--  if client_key_table ~= 'root' then
				--      print("client_key_table", tmux_get_env("client_key_table"))
				--  end

				--  local client_key_table = tmux_get_env("client_key_table")
			--  vim.print("client_key_table: " .. tmux_get_env("client_key_table"))
				--  if client_key_table ~= 'root' then
				--      print("client_key_table", tmux_get_env("client_key_table"))
				--  end

				--  The following operations will insert "*CC*" to editor files
				--  if tmux_get_env("client_prefix") == '1' then
				--      reverse(0)
				--  else
				--      restore(0)
				--  end

				--  tmux_escape_key_cancel()
				--  tmux_assist_key_cancel()
				local old_mode = ""
				if
					vim.v.event ~= nil and
					type(vim.v.event) == "table" and
					vim.v.event.old_mode ~= nil
					then
					old_mode = vim.v.event.old_mode
				end
					local new_mode = vim.api.nvim_get_mode().mode
					enable_conditional(new_mode, old_mode) --  Sometimes lost Escape?

					--  tmux_escape_reenable(new_mode, "")
					--  tmux_assist_reenable(new_mode, "")
			end
		end,
	})

--  if false then
	vim.api.nvim_create_autocmd({ "BufEnter",  "WinEnter", "WinNew" }, { --  , "BufHidden"
		group = vim.api.nvim_create_augroup("tmux_prefix_winenter", { clear = true }),
		pattern = { "*" },
		callback = function(args)
			if  --  true
				tmux_get_option("is-vim", "-t ".. tmux.execute("display -p '#{pane_id}'") .. " -pqv", "") == 'on'
				and tmux_get_option("is-insert", "-pqv", "") ~= 'on'
				and not has_floating_window(0) --  Without this, Telescope will initially enter normal mode
				then
				local old_mode = ""
				if
					vim.v.event ~= nil and
					type(vim.v.event) == "table" and
					vim.v.event.old_mode ~= nil
					then
					old_mode = vim.v.event.old_mode
				end
				local new_mode = vim.api.nvim_get_mode().mode
					enable_conditional(new_mode, old_mode) --  Sometimes lost Escape?
					--  tmux_escape_reenable(new_mode, "")
					--  tmux_assist_reenable(new_mode, "")
				if tmux_get_env("client_prefix") == '1' then
					reverse(0, "default_background")
				else
					restore(0)
				end
				--  Do not enter prefix mode when entering a float window
				if has_floating_window(0) then
					--  tmux_escape_key_cancel()
					--  tmux_assist_key_cancel()
					return false
				end

				if tmux_get_env("prefix_closed_loop", "-gh", "") ~= '1' then return false end
				print("WinEnter", "for prefix closed loop")
				if tmux_get_env("default_mode", "-gh", "") ~= '1' then return false end
				print("WinEnter", "for default mode")
				reverse(0, "default_background")
			--  restore(0)
			--  tmux.execute(string.format("run -C '%s'", escape_on_root_alias_name)) --  recursive call

				if tmux_get_env("client_prefix") == '0' then
					tmux.execute(string.format("%s", "switch-client -T prefix"))
				end
			--  tmux.execute(string.format("run -C '%s'", "#{color_prefix}")) --  send-keys inside #{color_prefix}
			--  tmux.execute(string.format("%s", "send-keys Escape Enter"))
			end
		end,
	})
--  end

	--  https://vi.stackexchange.com/questions/38567/detecting-visual-mode-enter-and-exit-events
	local visual_event_group =
	vim.api.nvim_create_augroup("visual_event", { clear = true })

	--  Entering visual-mode/replace-mode
	vim.api.nvim_create_autocmd("ModeChanged", {
		group = visual_event_group,
		pattern = { "*:[rRvV\x16]*" },
		callback = function()
			print("VisualEnter")
			tmux.execute(string.format("set-option -p -u -t '%s' '@%s'", tmux.get_tmux_pane(), 'is-insert'))
			tmux.execute(string.format("set-option -p -t '%s' '@%s' %s", tmux.get_tmux_pane(), 'is-visual', 'on'))
			tmux_escape_key_cancel()
			tmux_assist_key_cancel()
		end,
	})

	--  Quiting visual-mode/replace-mode
	vim.api.nvim_create_autocmd("ModeChanged", {
		group = visual_event_group,
		pattern = { "[rRvV\x16]*:*" },
		callback = function()
			print("VisualLeave")
			tmux.execute(string.format("set-option -p -u -t '%s' '@%s'", tmux.get_tmux_pane(), 'is-visual'))
			local new_mode = vim.api.nvim_get_mode().mode
			--  enable_conditional(new_mode, old_mode)
			tmux_escape_reenable(new_mode, "")
			tmux_assist_reenable(new_mode, "")
		end,
	})


	--  vim.api.nvim_create_autocmd({ "InsertCharPre", "FocusLost", "CursorMoved", "CursorMovedI", "WinLeave" }, { --  , "BufHidden"
	--  vim.api.nvim_create_autocmd({ "WinEnter", "WinResized", "WinNew", "WinClosed", "WinLeave", 'WinScrolled' }, { --  , "BufHidden"
	--      group = vim.api.nvim_create_augroup("tmux_prefix_winleave", { clear = true }),
	--      pattern = { "*" },
	--      callback = function(args)
	--          --  print("window-active-style backgound", backgound)
	--          --  local backgound = tmux_get_option("window-active-style", '-pqv', 'terminal')
	--          --  local backgound = tmux.execute("show -pqv window-active-style | awk -F = '$2 = $2 {print $2}'")
	--          --  if backgound ~= "terminal" then
	--          --      tmux.execute("set -p window-active-style bg=terminal")
	--          --  end
	--              tmux.execute([[refresh-client]])
	--      end,
	--  })

	--  For replace-mode
		--  map({ 'i' }, '<M-' .. prefix_key .. '>',
		map({ 'i' }, '<' .. 'C-c' .. '>',
		function()
			floating_close()
			local new_mode = vim.api.nvim_get_mode().mode
			if string.find(new_mode, "[rR]") == nil then return false end
			if tmux_get_env("client_prefix") == '1' then
				tmux.execute(string.format("%s", prefix_quit))
				--  reverse(0)
			else
				--  restore(0)
			end
			restore(0)
		end, { noremap = true })

		map({ 'n' }, '<' .. 'C-c' .. '>',
		function()
			floating_close()
			--  local new_mode = vim.api.nvim_get_mode().mode
			--  if string.find(new_mode, "[rR]") == nil then return false end
				if tmux_get_env("client_prefix") == '1' then
					tmux.execute(string.format("%s", prefix_quit))
					--  reverse(0)
				else
					--  restore(0)
				end
			restore(0)
		end, { noremap = true })

	--  It might not be reliable -- too many vim implementation details
	--  '\' key open telescope or :ls, then Esc to quit to normal mode, then you need the following codes
	--  to recover the escape_key and assist_key
	--  command mode will receive the tmux send-keys into input dialog
--  if false then
	if escape_key ~= assist_key and escape_key ~= nil and escape_key ~= "" then
		--  https://vim.fandom.com/wiki/Avoid_the_escape_key
		--  map({ 'n', 'c' }, '<' .. assist_key .. '>',
		--  map({ 'n', 'c' }, '<' .. escape_key .. '>',
		map({ 'n' }, '<' .. escape_key .. '>',
	--  map({ 'n', 'c' }, '<C-W>',
		function()
			--  https://stackoverflow.com/questions/73850771/how-to-get-all-of-the-properties-of-window-in-neovim

			print("Entering escape map")
			vim.print("Entering escape map")

			floating_close()

			--  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-c>", true, true, true), 'n', false)

			if os.getenv("TMUX") ~= nil then
				vim.print("Enabling escape and assist keys")
				local old_mode = ""
				if
					vim.v.event ~= nil and
					type(vim.v.event) == "table" and
					vim.v.event.old_mode ~= nil
					then
					old_mode = vim.v.event.old_mode
				end
				local new_mode = vim.api.nvim_get_mode().mode
					enable_conditional(new_mode, old_mode)
					--  tmux_escape_reenable(new_mode, "")
					--  tmux_assist_reenable(new_mode, "")
				-- tmux.execute("if -F '#{pane_in_mmode}' 'send-keys -X cancel' 'copy-mode'")
				tmux.execute(string.format("run -C '%s'", escape_on_root_alias_name)) --  recursive call ?
			end

			--  [For vim 9.1](https://vimhelp.org/popup.txt.html)
			--  vim.cmd[[
			--  let id = popup_findinfo()
			--  :call popup_clear(1)
			--  ]]

			--  if has_floating_window(0) then

			-- end
			--
			--  tmux.execute(string.format("run -C '%s'", escape_on_root_alias_name)) --  recursive call
			--
			--  tmux.execute("set -p window-active-style bg=terminal")
			if tmux_get_env("vim_in_charge_of_keystrokes", "-gh", "") == "0" then
				return true
			end

			local client_prefix = tmux_get_env("client_prefix")
		--  vim.print("client_prefix: " .. client_prefix)
				print("client_prefix", client_prefix)
			local mode_cur = tmux_get_option("mode-cur", "-pqv", "")
		--  vim.print("@mode-cur: " .. mode_cur)
				print("@mode-cur", mode_cur)
			local client_key_table = tmux_get_env("client_key_table")
		--  vim.print("client_key_table: " .. tmux_get_env("client_key_table"))
				print("client_key_table", tmux_get_env("client_key_table"))
		--  if tmux_get_option("client_prefix", "-pqv", "0") == '1' then
		--  tmux display -p "#{client_key_table}"
			if
				tmux_get_env("client_prefix") == "1" and
				vim.opt_local.background:get() == default_background and
				tmux_get_env("current_background", "-gh", "") == default_background and
			--  tmux_get_env("client_key_table") == "root" and
				tmux_get_option("mode-cur", "-pqv", "") == 'root'
				then
				reverse(0, "default_background")
				print("sending", "<C-W>")
				vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-W>", true, true, true), 'n', false)
			else
				restore(0)
				print("sending", "<C-c>")
				vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-c>", true, true, true), 'n', false)
			end
		end, { noremap = true })
	end
--  end

	--  local delegate_wincmd = tmux.execute('show-options -gqv "@tmux-delegates-wincmd"')
	local delegate_wincmd = tmux_get_env("delegate_wincmd")
	print("delegate_wincmd", delegate_wincmd)
	if delegate_wincmd == "1" then return true end

	local vim_in_charge_of_keystrokes = tmux_get_env("vim_in_charge_of_keystrokes")
	print("vim_in_charge_of_keystrokes", vim_in_charge_of_keystrokes)
	if vim_in_charge_of_keystrokes ~= "1" then return true end


--  if delegate_wincmd ~= "1" then
	vim.api.nvim_create_autocmd({ "WinLeave" }, { --  , "BufHidden"
		group = vim.api.nvim_create_augroup("tmux_prefix_winleave", { clear = true }),
		pattern = { "*" },
		callback = function(args)
			print("WinLeave", "recover background")
			restore(0)
		end,
	})

	--  vim.api.nvim_create_autocmd({ 'WinLeave', 'WinClosed', 'WinNew', 'WinScrolled', 'WinResized', 'WinEnter'}, {
	--      desc = 'Tmux sent prefix and mapped to <C-w>',
	--      group = vim.api.nvim_create_augroup('TmuxWincmd', { clear = true }),
	--      pattern = "*",
	--      callback = function(args)
	--          if os.getenv("TMUX") ~= nil then
	--              tmux .execute('set -p window-active-style bg=terminal')
	--          end
	--      end,
	--  })

	map('n', '<C-w>r',
	function()
		if os.getenv("TMUX") ~= nil then
			--  tmux.execute('source-file "' .. os.getenv('DOT_CONFIG') .. '/terminal/tmux.conf"')
			--  tmux.execute('source-file "' .. options.tmux.conf .. '"')
			--  if tmux_get_option("is-insert", "-pqv", "") ~= "" then
			tmux.execute(string.format("set-option -p -u -t '%s' '@%s'", tmux.get_tmux_pane(), 'is-insert'))
			--  end
		end
	end, { noremap = true })

	--  map({ 'n' }, '<' .. escape_key .. '>',
	--  function()
	--      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<C-w>', true, false, true), 'm', true)
	--  end, { noremap = true })

	--  Recursively calling if feedkeys ?
	--  if escape_key ~= "" then
	--      map({ 'n' }, '<' .. escape_key .. '>',
	--      function()
	--          ---  if escape_key ~= "" and tmux_runtime_bind(escape_key, 'root', false, false) == "" then
	--          --  tmux.execute('source-file "' .. options.prefix.conf .. '"')
	--          local new_mode = vim.api.nvim_get_mode().mode
	--          tmux_escape_reenable(new_mode, "")
	--          tmux_assist_reenable(new_mode, "") require"cmp.utils.feedkeys".run(3)
	--          loating_window(0) then
	--
	--
	--
	--          --  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(escape_key, true, false, true), 'm', true)
	--          --  end
	--      end, { noremap = true })
	--  end

	--  if assist_key ~= nil and assist_key ~= "" then
	--      --  map({ 'n' }, '<' .. assist_key .. '>',
	--      map({ 'n' }, assist_key,
	--      function()
	--          if tmux_get_env("pane_in_mode") == '1' then
	--              restore(0)
	--          else
	--              reverse(0)
	--          end
	--      end, { noremap = true })
	--  end

	if false then
		--  map({ 'n' }, '<' .. 'C-W' .. '>',
		map({ 'n' }, '<' .. 'C-c' .. '>',
		function()
			if tmux_get_env("client_prefix") == '1' then
				restore(0)
			else
				reverse(0, "default_background")
			end
		end, { noremap = true })
	end

	--  if escape_key == assist_key and "Escape" == assist_key then
	--  --  map({ 'c' }, '<' .. assist_key .. '>',
	--      map({ 'c' }, assist_key,
	--      function()
	--          if os.getenv("TMUX") ~= nil then
	--              tmux.execute("if '#{pane_in_mmode}' 'copy-mode' 'display \"not in copy-mode\" '")
	--          end
	--          --  require("notify").dismiss() --  popup window
	--      end, { noremap = true })

	--      map({ 'n' }, '<' .. assist_key .. '>',
	--      function()
	--          if os.getenv("TMUX") ~= nil then
	--              tmux.execute(vim.api.nvim_replace_termcodes("switch-client -T prefix ", true, true,true))
	--              --  tmux.execute(vim.api.nvim_replace_termcodes("set -p window-active-style bg=$prefix_background,reverse", true, true,true))
	--              tmux.execute(vim.api.nvim_replace_termcodes("display-panes -N", true, true,true))
	--          end
	--      end, { noremap = true })
	--  end

--  end --  delegate_wincmd ~= "1"

end

reload = function()
	--  https://vi.stackexchange.com/questions/44080/how-can-i-force-a-reload-on-a-previously-required-module
	--  https://neovim.discourse.group/t/reload-init-lua-and-all-require-d-scripts/971/10
	for name,_ in pairs(package.loaded) do
		if name:match('^tmux') then
			package.loaded[name] = nil
		end
	end
	event = 'reload'
	print("tmux", "reloading")
	--  package.loaded.tmux = nil
	--  require('tmux').setup()
		require('tmux').setup(options)
	--  https://stackoverflow.com/questions/75490124/how-to-require-a-file-with-a-dot-in-the-name
	--  dofile(options.user_preferences)
		init(event)
		prefix_toggle()
	dofile(vim.env.MYVIMRC)
	print("tmux", "reloaded")
	if default_background ~= vim.opt_local.background:get() then
		restore(0)
	end
	local client_prefix = tmux_get_env("client_prefix")
	--  vim.print("client_prefix: " .. client_prefix)
	print("client_prefix", client_prefix)
	local mode_cur = tmux_get_option("mode-cur", "-pqv", "")
	--  vim.print("@mode-cur: " .. mode_cur)
	print("@mode-cur", mode_cur)
	local client_key_table = tmux_get_env("client_key_table")
	--  vim.print("client_key_table: " .. tmux_get_env("client_key_table"))
	print("client_key_table", tmux_get_env("client_key_table"))
	if
		tmux_get_env("client_prefix") == "1" or
		tmux_get_option("mode-cur", "-pqv", "") == 'prefix' or
		tmux_get_env("client_key_table") == "prefix"
		then
			tmux.execute(string.format("%s", prefix_quit))
		end
	--  Useless
	--  if tmux_get_env("pane_in_mode") == '1' then
	--      tmux.execute("send-keys -X cancel")
	--  end
		vim.cmd[[redraw!]]
end

local M = {
	event         = event,
	reload        = reload,
	init          = init,
	prefix_toggle = prefix_toggle,
}

return M
