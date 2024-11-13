#! /bin/sh

type print > /dev/null 2>&1 ||
alias print='printf "[%6.6d] %-$((${LENGTH_HEADER:-59} - 10))s '"'"'%s'"'"'\n" "$LINENO"'

[ "$(readlink -fn "$(command -v "${0#"${0%%[!-]*}"}" 2> /dev/null || :)")" != "$(readlink -fn /proc/$$/exe)" ] ||
{
	print 'source running' 'is not supported'
	return 1
}

: "${tmux:="$( \
	command -v $(which tmux)               ||
	command -v /usr/bin/tmux 2> /dev/null  ||
	command -v /bin/tmux     2> /dev/null
	)"}" || { print 'tmux' "compiler cxx not found"; exit 1; }

export tmux

tmux() { $tmux "$@"; }

get_tmux_option() {
	local option="$1"
	local option_value &&
	option_value=$(tmux show-options -gqv "$option")
	[ -z "${option_value:+x}" ] &&
		printf '%s' "$2" ||
		printf '%s' "$option_value"
}

get_tmux_env() {
	local key="$1"
	# prefix_background="colour003"  # in tmux.conf
	local key_value="$(tmux showenv -g "$key" | awk -F = '$2 = $2 {print $2}')"
	[ ! -z "${key_value:+x}" ]  ||
		key_value="$(tmux showenv -gh "$key" | awk -F = '$2 = $2 {print $2}')"
	# For %hidden key/value in tmux
	# %hidden assist_key="Escape" # in tmux.conf
	[ ! -z "${key_value:+x}" ]  ||
		key_value="$(tmux display -p "#{$key}")"
	printf '%s' "$key_value"
}

get_tmux_bind() {
	local mode="$1"
	local key="$2"
	tmux list-keys -T "$mode" | awk -v key="$key" '$4 == key {print}'
}

# @is-vim has only two states: empty or 'on' -- no true/false, on/off, no 0/1, especially has no undefined
# On Void Linux, vim is named vim-huge or vim :(
# is_vim="ps -o state= -o comm= -t '#{pane_tty}' | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?\.?(view|n?vim?x?)(-wrapped)?(diff)?$'"

# Usage
# sh -c '/home/ei/.local/share/nvim/lazy/tmux.nvim/tmux.nvim.tmux prefix_wincmd prefix_only'
# sh -c '/home/ei/.local/share/nvim/lazy/tmux.nvim/tmux.nvim.tmux prefix_wincmd "" mode_only'
prefix_wincmd() {
	$(get_tmux_option "@prefix-triggers-wincmd" true) ||
			{ print 'got false on' "@prefix-triggers-wincmd"; return 1; }

	local prefix_only="$1"
	local mode_only="$2"

	local escape_key="$(get_tmux_env 'escape_key')"
	[ ! -z "${escape_key:+x}" ] ||
	{
		tmux display -p 'escape_key not found'
		tmux setenv  -g 'escape_key' '`'
	}
	local prefix_background="$(get_tmux_env "prefix_background")"
	[ ! -z "${prefix_background:+x}" ] ||
	{
		tmux display -p 'prefix_background not found'
		tmux setenv  -g 'prefix_background' 'colour003'
	}
	local normal_background="$(get_tmux_env "normal_background")"
	[ ! -z "${normal_background:+x}" ] ||
	{
		tmux display -p 'normal_background not found'
		tmux setenv  -g 'normal_background' 'colour000'
	}

	# local delegate_wincmd="$(get_tmux_option "@tmux-delegates-wincmd" "")"
	local delegate_wincmd="$(get_tmux_env "delegate_wincmd" "")"

	[ "$#" -ne 0 ] && [ -z "${prefix_only:+x}" ] ||
	{
		local prefix_per_se="$(get_tmux_bind "prefix" "$escape_key")"
		[ -n "${prefix_per_se:+x}" ] && print 'cancelled for defined in configuration' "$prefix_per_se" ||
		{
			[ "${delegate_wincmd}" ] &&
			# Version 0
			# tmux bind -T prefix       "$escape_key" if-shell -F '#{@is-vim}' ' send-keys C-w ' ' switch-client -T root   ; set -g window-active-style bg=terminal '
			# Version 2
			tmux bind -T prefix       "$escape_key" if-shell true ' switch-client -T root   ; set -g window-active-style bg=terminal ' ||
			# Version 1
			tmux bind -T prefix       "$escape_key" if-shell -F '#{@is-vim}' ' copy-mode ; set -g window-active-style bg=$normal_background ' ' switch-client -T root ; set -g window-active-style bg=terminal '

		}

		local prefix_root="$(get_tmux_bind "root" "$escape_key")"
		[ -n "${prefix_root:+x}" ] && print 'cancelled for defined in configuration' "$prefix_root" ||
		{
			[ "${delegate_wincmd}" ] &&
			# Version 0 -- only sends <C-w>
			# tmux bind -T root         "$escape_key" if-shell -F '#{@is-vim}' ' send-keys C-w ' ' switch-client -T prefix ; set -g window-active-style bg=$prefix_background,reverse '
			# Version 2 -- tmux delegates vim <C-w>
			tmux bind -T root         "$escape_key" if-shell true ' switch-client -T prefix ; set -g window-active-style bg=$prefix_background,reverse ' ||
			# Version 1 -- let vim determine what to do -- too much modes between tmux and vim
			tmux bind -T root         "$escape_key" if-shell true ' if-shell -F "#{@is-vim}" " send-keys $escape_key " " switch-client -T prefix " ; set -g window-active-style bg=$prefix_background,reverse '
		}
		return 0
	}

	[ "$#" -ne 0 ] && [ -z "${mode_only:+x}" ] ||
	{
		local prefix_copy_mode_vi="$(get_tmux_bind "copy-mode-vi" "$escape_key")"
		[ -n "${prefix_copy_mode_vi:+x}" ] && print 'cancelled for defined in configuration' "$prefix_copy_mode_vi" ||
		  tmux bind -T copy-mode-vi "$escape_key" if-shell true ' switch-client -T prefix ; set -g window-active-style bg=$prefix_background,reverse '
		local prefix_copy_mode="$(get_tmux_bind "copy-mode" "$escape_key")"
		[ -n "${prefix_copy_mode:+x}" ] && print 'cancelled for defined in configuration' "$prefix_copy_mode" ||
		  tmux bind -T copy-mode    "$escape_key" if-shell true ' switch-client -T prefix ; set -g window-active-style bg=$prefix_background,reverse '
		return 0
	}

	local prefix_k="$(get_tmux_bind "prefix" "k")"
	[ -n "${prefix_k:+x}" ] && print 'cancelled for defined in configuration' "$prefix_k" ||
	[ -s "$XDG_CONFIG_HOME/tmux/wincmd.conf" ] &&
	tmux source "$XDG_CONFIG_HOME/tmux/wincmd.conf" ||
	{

		[ ! "${delegate_wincmd}" ] ||
		{
			tmux bind-key -T prefix v    if-shell -F '#{@is-vim}' ' send-keys C-w v ' \; set -g window-active-style bg=terminal
			tmux bind-key -T prefix n    next-window \; set -g window-active-style bg=terminal
			tmux bind-key -T prefix s    if-shell -F '#{@is-vim}' ' send-keys C-w s ' \; set -g window-active-style bg=terminal
			tmux bind-key -T prefix q    if-shell -F '#{@is-vim}' ' send-keys C-w c ' \; set -g window-active-style bg=terminal

			tmux unbind h
			tmux bind-key -T prefix    h if-shell -F '#{@is-vim}' ' send-keys C-w h ' ' select-pane -L ' \; set -g window-active-style bg=terminal
			tmux unbind j
			tmux bind-key -T prefix    j if-shell -F '#{@is-vim}' ' send-keys C-w j ' ' select-pane -D ' \; set -g window-active-style bg=terminal
			tmux unbind k
			tmux bind-key -T prefix    k if-shell -F '#{@is-vim}' ' send-keys C-w k ' ' select-pane -U ' \; set -g window-active-style bg=terminal
			tmux unbind l
			tmux bind-key -T prefix    l if-shell -F '#{@is-vim}' ' send-keys C-w l ' ' select-pane -R ' \; set -g window-active-style bg=terminal

			tmux bind-key -T prefix    H if-shell -F '#{@is-vim}' ' send-keys C-w H ' \; set -g window-active-style bg=terminal
			tmux bind-key -T prefix    J if-shell -F '#{@is-vim}' ' send-keys C-w J ' \; set -g window-active-style bg=terminal
			tmux bind-key -T prefix    K if-shell -F '#{@is-vim}' ' send-keys C-w K ' \; set -g window-active-style bg=terminal
			tmux bind-key -T prefix    L if-shell -F '#{@is-vim}' ' send-keys C-w L ' \; set -g window-active-style bg=terminal
		}
	}
}

# navigation
#
ctrl_navigation() {
	$(get_tmux_option "@tmux-nvim-navigation" true) ||
		{ print 'got false on' "@tmux-nvim-navigation"; return 1; }

	local  left=$(get_tmux_option "@tmux-nvim-navigation-keybinding-left"  'C-h')
	local  down=$(get_tmux_option "@tmux-nvim-navigation-keybinding-down"  'C-j')
	local    up=$(get_tmux_option "@tmux-nvim-navigation-keybinding-up"    'C-k')
	local right=$(get_tmux_option "@tmux-nvim-navigation-keybinding-right" 'C-l')

	$(get_tmux_option "@tmux-nvim-navigation-cycle" true) &&
	{
		tmux bind-key -n "$up"    if-shell -F "#{@is-vim}" "send-keys $up"    'select-pane -U'
		tmux bind-key -n "$down"  if-shell -F "#{@is-vim}" "send-keys $down"  'select-pane -D'
		tmux bind-key -n "$left"  if-shell -F "#{@is-vim}" "send-keys $left"  'select-pane -L'
		tmux bind-key -n "$right" if-shell -F "#{@is-vim}" "send-keys $right" 'select-pane -R'

		tmux bind-key -T copy-mode-vi "$up"    select-pane -U
		tmux bind-key -T copy-mode-vi "$down"  select-pane -D
		tmux bind-key -T copy-mode-vi "$left"  select-pane -L
		tmux bind-key -T copy-mode-vi "$right" select-pane -R
	} ||
	{
		tmux bind-key -n "$up"    if-shell -F "#{@is-vim}" "send-keys $up"    "if -F '#{pane_at_top}'    '' 'select-pane -U'"
		tmux bind-key -n "$down"  if-shell -F "#{@is-vim}" "send-keys $down"  "if -F '#{pane_at_bottom}' '' 'select-pane -D'"
		tmux bind-key -n "$left"  if-shell -F "#{@is-vim}" "send-keys $left"  "if -F '#{pane_at_left}'   '' 'select-pane -L'"
		tmux bind-key -n "$right" if-shell -F "#{@is-vim}" "send-keys $right" "if -F '#{pane_at_right}'  '' 'select-pane -R'"

		tmux bind-key -T copy-mode-vi "$up"    "if -F '#{pane_at_top}'    '' 'select-pane -U'"
		tmux bind-key -T copy-mode-vi "$down"  "if -F '#{pane_at_bottom}' '' 'select-pane -D'"
		tmux bind-key -T copy-mode-vi "$left"  "if -F '#{pane_at_left}'   '' 'select-pane -L'"
		tmux bind-key -T copy-mode-vi "$right" "if -F '#{pane_at_right}'  '' 'select-pane -R'"
	}
}

# resize
#
alt_resize() {
	$(get_tmux_option "@tmux-nvim-resize" true) ||
		{ print 'got false on' "@tmux-nvim-resize"; return 1; }

	local step_x=$(get_tmux_option "@tmux-nvim-resize-step-x" 5)
	local step_y=$(get_tmux_option "@tmux-nvim-resize-step-y" 2)
	local   left=$(get_tmux_option "@tmux-nvim-resize-keybinding-left"  'M-h')
	local   down=$(get_tmux_option "@tmux-nvim-resize-keybinding-down"  'M-j')
	local     up=$(get_tmux_option "@tmux-nvim-resize-keybinding-up"    'M-k')
	local  right=$(get_tmux_option "@tmux-nvim-resize-keybinding-right" 'M-l')

	tmux bind -n "$up"    if-shell -F "#{@is-vim}" "send-keys $up"    "resize-pane -U $step_y"
	tmux bind -n "$down"  if-shell -F "#{@is-vim}" "send-keys $down"  "resize-pane -D $step_y"
	tmux bind -n "$left"  if-shell -F "#{@is-vim}" "send-keys $left"  "resize-pane -L $step_x"
	tmux bind -n "$right" if-shell -F "#{@is-vim}" "send-keys $right" "resize-pane -R $step_x"

	tmux bind-key -T copy-mode-vi "$up"    resize-pane -U "$step_y"
	tmux bind-key -T copy-mode-vi "$down"  resize-pane -D "$step_y"
	tmux bind-key -T copy-mode-vi "$left"  resize-pane -L "$step_x"
	tmux bind-key -T copy-mode-vi "$right" resize-pane -R "$step_x"
}

main() {
	local action="${1-}"
	shift 1
	[ -z "${action:+x}" ] &&
	{
		prefix_wincmd
		ctrl_navigation
		alt_resize

		# [ -n "${TMUX_TMPDIR:+x}" ] || TMUX_TMPDIR="$HOME/${HOST_NAME:=$(hostname)}"; [ -d "$TMUX_TMPDIR" ] || \mkdir -p "$TMUX_TMPDIR"; : > $TMUX_TMPDIR/tmux.log
		# : > "$TMUX_TMPDIR/tmux.log"

		tmux display '#[fill=white bg=black align=left]tmux.nvim.tmux loaded' \; set -u message-style
	} ||
	{
		case "$action" in "prefix_wincmd"|"ctrl_navigation"|"alt_resize")
			"$action" "$@"
			printf '%s(%s) updated\n' "$action" "${@-}" | tee -a "$TMUX_TMPDIR/tmux.log" >> "$HOME/.vim.log"
			# Heavy operation
			# tmux display "#[fill=white bg=black align=left]$action updated"
			;;
			*)
				print "$action" "is not supported"
				return 1
		esac
	}
}

main "$@" || exit 1




