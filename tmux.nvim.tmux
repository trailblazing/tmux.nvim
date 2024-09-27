#! /bin/sh

get_tmux_option() {
	local option="$1"
	local option_value &&
	option_value=$(tmux show-options -gqv "$option")
	[ -z "${option_value:+x}" ] &&
		printf '%s' "$2" ||
		printf '%s' "$option_value"
}

# is_vim="ps -o state= -o comm= -t '#{pane_tty}' | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?\.?(view|n?vim?x?)(-wrapped)?(diff)?$'"

# navigation
#

 navigation_enabled=$(get_tmux_option "@tmux-nvim-navigation" true)
   navigation_cycle=$(get_tmux_option "@tmux-nvim-navigation-cycle" true)
 navigation_kb_left=$(get_tmux_option "@tmux-nvim-navigation-keybinding-left"  'C-h')
 navigation_kb_down=$(get_tmux_option "@tmux-nvim-navigation-keybinding-down"  'C-j')
   navigation_kb_up=$(get_tmux_option "@tmux-nvim-navigation-keybinding-up"    'C-k')
navigation_kb_right=$(get_tmux_option "@tmux-nvim-navigation-keybinding-right" 'C-l')

! $navigation_enabled ||
$navigation_cycle &&
{
	tmux bind-key -n "$navigation_kb_left"  if-shell -b '[ "$(tmux show -pqv '@is-vim')" = "on" ]' "send-keys $navigation_kb_left"  'select-pane -L'
	tmux bind-key -n "$navigation_kb_down"  if-shell -b '[ "$(tmux show -pqv '@is-vim')" = "on" ]' "send-keys $navigation_kb_down"  'select-pane -D'
	tmux bind-key -n "$navigation_kb_up"    if-shell -b '[ "$(tmux show -pqv '@is-vim')" = "on" ]' "send-keys $navigation_kb_up"    'select-pane -U'
	tmux bind-key -n "$navigation_kb_right" if-shell -b '[ "$(tmux show -pqv '@is-vim')" = "on" ]' "send-keys $navigation_kb_right" 'select-pane -R'

	tmux bind-key -T copy-mode-vi "$navigation_kb_left"  select-pane -L
	tmux bind-key -T copy-mode-vi "$navigation_kb_down"  select-pane -D
	tmux bind-key -T copy-mode-vi "$navigation_kb_up"    select-pane -U
	tmux bind-key -T copy-mode-vi "$navigation_kb_right" select-pane -R
} ||
{
	tmux bind-key -n "$navigation_kb_left"  if-shell -b '[ "$(tmux show -pqv '@is-vim')" = "on" ]' "send-keys $navigation_kb_left"  "if -F '#{pane_at_left}'   '' 'select-pane -L'"
	tmux bind-key -n "$navigation_kb_down"  if-shell -b '[ "$(tmux show -pqv '@is-vim')" = "on" ]' "send-keys $navigation_kb_down"  "if -F '#{pane_at_bottom}' '' 'select-pane -D'"
	tmux bind-key -n "$navigation_kb_up"    if-shell -b '[ "$(tmux show -pqv '@is-vim')" = "on" ]' "send-keys $navigation_kb_up"    "if -F '#{pane_at_top}'    '' 'select-pane -U'"
	tmux bind-key -n "$navigation_kb_right" if-shell -b '[ "$(tmux show -pqv '@is-vim')" = "on" ]' "send-keys $navigation_kb_right" "if -F '#{pane_at_right}'  '' 'select-pane -R'"

	tmux bind-key -T copy-mode-vi "$navigation_kb_left"  "if -F '#{pane_at_left}'   '' 'select-pane -L'"
	tmux bind-key -T copy-mode-vi "$navigation_kb_down"  "if -F '#{pane_at_bottom}' '' 'select-pane -D'"
	tmux bind-key -T copy-mode-vi "$navigation_kb_up"    "if -F '#{pane_at_top}'    '' 'select-pane -U'"
	tmux bind-key -T copy-mode-vi "$navigation_kb_right" "if -F '#{pane_at_right}'  '' 'select-pane -R'"
}

# resize
#

 resize_enabled=$(get_tmux_option "@tmux-nvim-resize" true)
  resize_step_x=$(get_tmux_option "@tmux-nvim-resize-step-x" 5)
  resize_step_y=$(get_tmux_option "@tmux-nvim-resize-step-y" 2)
 resize_kb_left=$(get_tmux_option "@tmux-nvim-resize-keybinding-left"  'M-h')
 resize_kb_down=$(get_tmux_option "@tmux-nvim-resize-keybinding-down"  'M-j')
   resize_kb_up=$(get_tmux_option "@tmux-nvim-resize-keybinding-up"    'M-k')
resize_kb_right=$(get_tmux_option "@tmux-nvim-resize-keybinding-right" 'M-l')

! $resize_enabled ||
{
	tmux bind -n "$resize_kb_left"  if-shell -b '[ "$(tmux show -pqv '@is-vim')" = "on" ]' "send-keys $resize_kb_left"  "resize-pane -L $resize_step_x"
	tmux bind -n "$resize_kb_down"  if-shell -b '[ "$(tmux show -pqv '@is-vim')" = "on" ]' "send-keys $resize_kb_down"  "resize-pane -D $resize_step_y"
	tmux bind -n "$resize_kb_up"    if-shell -b '[ "$(tmux show -pqv '@is-vim')" = "on" ]' "send-keys $resize_kb_up"    "resize-pane -U $resize_step_y"
	tmux bind -n "$resize_kb_right" if-shell -b '[ "$(tmux show -pqv '@is-vim')" = "on" ]' "send-keys $resize_kb_right" "resize-pane -R $resize_step_x"

	tmux bind-key -T copy-mode-vi "$resize_kb_left"  resize-pane -L "$resize_step_x"
	tmux bind-key -T copy-mode-vi "$resize_kb_down"  resize-pane -D "$resize_step_y"
	tmux bind-key -T copy-mode-vi "$resize_kb_up"    resize-pane -U "$resize_step_y"
	tmux bind-key -T copy-mode-vi "$resize_kb_right" resize-pane -R "$resize_step_x"
}

tmux display -p 'tmux.nvim.tmux loaded'







