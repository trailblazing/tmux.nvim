# tmux.nvim

1.  In this version of tmux.nvim, in theory any single key can be used as a prefix key without breaking the existing definition of that key in most modes - this means that the framework is designed to be orthogonal, and these keys can work independently without the help of Ctrl/Alt or other sticky keys. There is indeed a switch variable (one_key_prefix) in the settings file that swaps a given pair of prefix and auxiliary keys. You need to reload the tmux settings file to switch, and restart the editor when redefining the keys - people can try different combinations and settle on a comfortable pattern for a while.

    The implementation principle is based on tmux's ability to dynamically disable and enable keyboard bindings: that is, it implements new functions by dynamically expanding the unused pattern space while respecting the original function definitions for specific modes.

    Specifically, given a set of prefix keys (assuming Escape is set as the primary prefix mode initiator and Backtick is set as the copy mode initiator or vice versa). By dynamically enabling and disabling these functions, tmux's prefix functions do not interfere with the original input functions of the specific mode in the editor or terminal. For example, you don't have to worry about the tmux prefix attribute of the Escape key giving you surprises in the editor's insert mode. To use Backtick as an auxiliary prefix, you don't have to hit the Backtick key twice or use Alt-Backtick to enter a Backtick character in the editor or terminal.

    This design does not force users to use a fixed configuration or mode - it tries to provide a framework to help people find the most suitable usage habits. After applying these definitions, you will feel that some keys are more sensitive than before, because this design makes full use of the blank space of the original mode instead of adding new definitions, and your previous related muscle memory has never been established. If you do find a "wrong" definition, it may be necessary to modify the tmux.nvim settings file to avoid conflicts with your usage habits.

    In order to correctly implement the above-mentioned deep integration of tmux and nvim, in addition to the necessary editor-side lua scripts, this version of tmux.nvim introduces a series of tmux configuration files through the git submodule [tmux](https://github.com/trailblazing/tmux): header.conf, prefix.conf, wincmd.conf, navigation.conf and resize.conf are the minimum necessary set. Those who are interested in trying this plugin are welcome to integrate these .conf files into your tmux instance configuration (done through the source command). If these files conflict with existing settings, the later imported settings will overwrite the previously defined functions. If this causes you to completely rewrite your tmux settings file, maybe it's worth it:)

    This design insists on decoupling editor/terminal and tmux. Don't worry about them affecting each other.

2.  Automatic clipboard synchronization between nvim and tmux. You can copy content from mvim to the terminal in tmux without switching to tmux's copy mode. This is very useful for complex and long text copying. Especially for pure tty editing, this is almost the most reasonable choice.

    On NVIM v0.10.1, the file [clipboard.vim](/usr/share/nvim/runtime/autoload/provider/clipboard.vim) has done most of the work on the editor side.

    What we need is to ensure a stable interface between tmux and nvim.

    Through [<b>tmux's system clipboard settings</b>](https://github.com/trailblazing/tmux/blob/main/tmux.conf), you can copy content to the system clipboard while copying to tmux in this combined environment without relying on the editor's association with the system clipboard.

    Once this plugin works, there is no need for ctrl-shift-{c, v} in the terminal inside tmux, nor the help of the mouse, even when coding in a GUI environment.

    There is a vim-tmux-clipboard, but they are slightly [different](https://github.com/trailblazing/dotconfig/blob/master/init/editor/nvim/lua/plugins/core.lua).

Based on the above scenario, I am happy to fork tmux.nvim, You are very welcome to improve these designs and provide feedback.


## Installation

On NVIM v0.10.1 one needs this clipboard [setting](https://github.com/trailblazing/dotconfig/blob/master/init/editor/nvim/lua/config.lua).
```lua
vim.opt.clipboard = { "unnamed", "unnamedplus" }
```
Install tmux.nvim with e.g. [lazy.nvim](https://github.com/folke/lazy.nvim):

[$XDG_CONFIG_HOME/nvim/lua/plugins/tmux.lua](https://github.com/trailblazing/dotconfig/blob/master/init/editor/nvim/lua/plugins/tmux.lua)


Tmux.nvim uses only `lua` API. If the default keybindings are not working , bind the following options to your liking.

```lua
return {
	"trailblazing/tmux.nvim",
	cond   = true,
	branch = 'main',
	event  = "TextYankPost", -- does not matter
	lazy   = true,
	config = function()
		opts    = {
			copy_sync = {
				enable          = true, -- default
				sync_clipboard  = true, -- default
				sync_registers  = true, -- default
				redirect_to_clipboard = false, -- default
			},
			tmux    = {
				conf    = os.getenv("HOME") .. "/.tmux.conf",
				header  = os.getenv("XDG_CONFIG_HOME") .. "/tmux/header.conf",
			},
			prefix  = {
				conf    = os.getenv("XDG_CONFIG_HOME") .. "/tmux/prefix.conf",
				wincmd  = os.getenv("XDG_CONFIG_HOME") .. "/tmux/wincmd.conf",
				--  The background color value indicating entering prefix "mode" when vim background is dark
				prefix_background   = "#00d7d7", -- "brightyellow",
				--  The background color value indicating entering copy-mode when nvim background is dark
				normal_background   = "colour003",
				--  The background color value indicating entering prefix "mode" when vim background is light
				prefix_bg_on_light  = "#d7d700",
				--  The background color value indicating entering copy-mode when nvim background is light
				normal_bg_on_light  = "colour003",
			},
			navigation = {
				conf    = os.getenv("XDG_CONFIG_HOME") .. "/tmux/navigation.conf",
				enable_default_keybindings = true, -- default
				cycle_navigation = true, -- default
			},
			resize = {
				conf    = os.getenv("XDG_CONFIG_HOME") .. "/tmux/resize.conf",
				enable_default_keybindings = true, -- default
			},
			logging = {
				file    = "debug",
				notify  = "disabled", -- not default
			},
		}
		return require("tmux").setup(opts, logging)
	end
}
```
Besides the bindings in nvim (done by this plugin) you need to add configuration to [.tmux.conf](https://github.com/trailblazing/tmux/blob/main/tmux.conf).
Because you want ot enable these functions before an editor's exists.
```tmux
#   Tmux .conf files that need to be inserted into the default tmux.conf, $XDG_CONFIG_HOME/tmux == $DOT_CONFIG/terminal/tmux
%if '[ -s "$XDG_CONFIG_HOME/tmux/header.conf" ]'
    source "$XDG_CONFIG_HOME/tmux/header.conf"
%endif

%if '[ -s "$XDG_CONFIG_HOME/tmux/prefix.conf" ]'
    source "$XDG_CONFIG_HOME/tmux/prefix.conf"
%endif

%if '[ -s "$XDG_CONFIG_HOME/tmux/wincmd.conf" ]'
    source "$XDG_CONFIG_HOME/tmux/wincmd.conf"
%endif

%if '[ -s "$XDG_CONFIG_HOME/tmux/navigation.conf" ]'
    source "$XDG_CONFIG_HOME/tmux/navigation.conf"
%endif

%if '[ -s "$XDG_CONFIG_HOME/tmux/resize.conf" ]'
    source "$XDG_CONFIG_HOME/tmux/resize.conf"
%endif

```
One variable switch prefix key and assistant prefix key in [header.conf](https://github.com/trailblazing/tmux/blob/main/header.conf).
```tmux
#   #AA0000 Binding prefix_key to Escape
    %hidden one_key_prefix=1
#   #00AAAA Binding normal_key to Escape
#   %hidden one_key_prefix=0
```
If you want to use Escape as a copy-mode initiator, the above code will become the following:
```tmux
#   #AA0000 Binding prefix_key to Escape
#   %hidden one_key_prefix=1
#   #00AAAA Binding normal_key to Escape
    %hidden one_key_prefix=0
```
Do not worry about Escape's functions of the editor, tmux prefix functions are on top of normal mode by design.

The reason I bind Escape to tmux prefix key by defaut is because I need a most reasonable key to quit the terminal input mode.

If you have no conflicting setup, that is it.

If you want to change the default prefix keys, finding the following code inside [header.conf](https://github.com/trailblazing/tmux/blob/main/header.conf)
```tmux
%if    "#{one_key_prefix}"
    %hidden prefix_key="Escape"
    %hidden normal_key="`"
%else
    %hidden normal_key="Escape"
    %hidden prefix_key="`"
%endif
```
and change to your preferences. Press 'r' under the tmux copy-mode will reload the tmux configuration if you use this
[tmux.conf](https://github.com/trailblazing/tmux/blob/main/tmux.conf).


## Usage

Forget it. Focus on our thinking and coding. Every thing seems to be the same as before, you just maintain consistency and assimilate the unnecessary complexity between the layers of the software system -- forget the additional layers of the terminal, such as ctrl-shift sequence of operation details. and the complex operation of the mouse in the editing environment can also be abandoned.

## Requirements

The plugin scripts are working in the following environment:
- neovim = v0.10.1
- tmux 3.4~3.5

But I don't think it's necessary.

## Configuration

The config step is only necessary to overwrite configuration defaults.

The following defaults are given:

```lua
{
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
		--  escape_key  = 'Escape',  --  Single key prefix trigger
		--  assist_key  = '',        --  Single key copy-mode trigger
		--  The background color value indicating entering prefix "mode" when vim background is dark
		prefix_background   = "colour007",
		--  The background color value indicating entering copy-mode when nvim background is dark
		normal_background   = "colour003",
		--  The background color value indicating entering prefix "mode" when vim background is light
		prefix_bg_on_light  = "colour006",
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
```


### Copy sync

Copy sync uses tmux buffers as master clipboard for `*`, `+`, `unnamed`, and `0` - `9` registers. The sync does NOT rely on temporary files and works just with the given tmux API. Thus, making it less insecure :). The feature enables a nvim instace overarching copy/paste process! yank/dd in one nvim instance, switch to the second and p the copies/deletes.

If we do not sync clipboard with a standalone tmux, disable `sync_clipboard` to ensure nvim handles yanks and deletes alone.

This has some downsites, on really slow machines, calling registers or pasting will eventually produce minimal input lag by syncing registers in advance to ensure the correctness of state. To avoid this, disabling `sync_registers` will only redirect the `*` and `+` registers.

To redirect copies (and deletes) to clipboard, tmux must have the capability to do so. The plugin will just set -w on set-buffer. If your tmux need more configuration check out [tmux-yank](https://github.com/tmux-plugins/tmux-yank) for an easy setup.

Ignoring buffers must have the form of `buffer_name = true` to enable an unsorted list in lua. This enhances the performance of checks - if a buffer is ignored or not - meaningfull.

### Prefix

Sourcing [`$XDG_CONFIG_HOME/tmux/header.conf`](https://github.com/trailblazing/tmux/blob/main/header.conf) and [`$XDG_CONFIG_HOME/tmux/prefix.conf`](https://github.com/trailblazing/tmux/blob/main/prefix.conf) in the [`~/.tmux.conf`](https://github.com/trailblazing/tmux/blob/main/tmux.conf) to enable prefix functions:

### Navigation

Sourcing [`$XDG_CONFIG_HOME/tmux/navigation.conf`](https://github.com/trailblazing/tmux/blob/main/navigation.conf) in the [`~/.tmux.conf`](https://github.com/trailblazing/tmux/blob/main/tmux.conf) to enable navigation functions:

"cycle-free" navigation beyond nvim is enabled by default in  [`$XDG_CONFIG_HOME/tmux/navigation.conf`](https://github.com/trailblazing/tmux/blob/main/navigation.conf):
```tmux
    %hidden disable_navigation_cycle=''
    setenv -ghu disable_navigation_cycle
```


The implemented lua scripts of the plugin ensure the key bindings of nvim match the defined bindings in the navigation.conf! Otherwise the pass through will not have the seamless effect!


You can change the above settings in your navigation.conf to the following to disable cycling navigation:

```tmux
    %hidden disable_navigation_cycle='on'
    setenv -gh  disable_navigation_cycle $disable_navigation_cycle
```

To run custom bindings in nvim, make sure to set `enable_default_keybindings` to `false` in [tmux.lua](https://github.com/trailblazing/dotconfig/blob/master/init/editor/nvim/lua/plugins/tmux.lua). The following definitions (in [navigation.lua](https://github.com/trailblazing/tmux.nvim/blob/main/lua/tmux/navigation/init.lua)) are used to navigate around windows and panes

```lua
{
	["<C-h>"]   = [[<cmd>lua require'tmux'.move_left()<cr>]],
	["<C-j>"]   = [[<cmd>lua require'tmux'.move_bottom()<cr>]],
	["<C-k>"]   = [[<cmd>lua require'tmux'.move_top()<cr>]],
	["<C-l>"]   = [[<cmd>lua require'tmux'.move_right()<cr>]],
	["<C-w>h"]  = [[<cmd>lua require'tmux'.move_left()<cr>]],
	["<C-w>j"]  = [[<cmd>lua require'tmux'.move_bottom()<cr>]],
	["<C-w>k"]  = [[<cmd>lua require'tmux'.move_top()<cr>]],
	["<C-w>l"]  = [[<cmd>lua require'tmux'.move_right()<cr>]],
}
```

### Resize

Sourcing [`$XDG_CONFIG_HOME/tmux/resize.conf`](https://github.com/trailblazing/tmux/blob/main/resize.conf) in the [`~/.tmux.conf`](https://github.com/trailblazing/tmux/blob/main/tmux.conf) to enable resize functions:

The implemented lua scripts of the plugin ensure the key bindings of nvim match the defined bindings in the resize.conf. Otherwise the pass through will not have the seamless effect!


To run custom bindings in nvim, make sure to set `enable_default_keybindings` to `false` in [tmux.lua](https://github.com/trailblazing/dotconfig/blob/master/init/editor/nvim/lua/plugins/tmux.lua). The following definitions (in [resize.lua](https://github.com/trailblazing/tmux.nvim/blob/main/lua/tmux/resize.lua)) are used to resize windows:

```lua
{
	["<A-h>"] = [[<cmd>lua require'tmux'.resize_left()<cr>]],
	["<A-j>"] = [[<cmd>lua require'tmux'.resize_bottom()<cr>]],
	["<A-k>"] = [[<cmd>lua require'tmux'.resize_top()<cr>]],
	["<A-l>"] = [[<cmd>lua require'tmux'.resize_right()<cr>]],
}
```

## Tpm

If you prefer [tmux plugin manager](https://github.com/tmux-plugins/tpm) (it is not necessary), you can add the following plugin.

```tmux
set -g @plugin 'trailblazing/tmux.nvim'

run '~/.tmux/plugins/tpm/tpm'
```

Available options for the plugin and their defaults are (if you use the defaults, these options are already inside navigation.conf/resize.conf):

```tmux
# navigation.conf
    %hidden  navigation_left='C-h'
    %hidden  navigation_down='C-j'
    %hidden    navigation_up='C-k'
    %hidden navigation_right='C-l'

```
```tmux
# resize.conf
    %hidden   resize_left='M-h'
    %hidden   resize_down='M-j'
    %hidden     resize_up='M-k'
    %hidden  resize_right='M-l'
    %hidden resize_step_x=5
    %hidden resize_step_y=2

```

## Troubleshoot

### Window switching stops working in python virtual environment

> [christoomey/vim-tmux-navigator#295](https://github.com/christoomey/vim-tmux-navigator/issues/295)

To enable searching for nvim in subshells, you need to change the 'is_vim' part in the tmux plugin. This will make searching for nested nvim instances result in positive resolutions.

Found by @duongapollo

Since we changed from is_vim to @is-vim, no such issues should occur again. Just make sure @is-vim is set in nvim/vim and
[tmux.nvim](https://github.com/trailblazing/tmux.nvim) or [keys.vim](https://github.com/trailblazing/keys) is loaded correctly.

### Compatibility with vim-yoink or other yank-related tmux-plugins

> [aserowy/tmux.nvim#88](https://github.com/aserowy/tmux.nvim/issues/88)

The configuration in the given issue integrates tmux.nvim with yanky.nvim and which-key.nvim so we get the benefits of all yank-related plugins.

Found by @kiyoon

## Contribute

Contributed code must pass [luacheck](https://github.com/mpeterv/luacheck) and be formatted with [stylua](https://github.com/johnnymorganz/stylua). Besides formatting, all tests have to pass. Tests are written for [busted](https://github.com/Olivine-Labs/busted).

If you are using nix-shell, you can start a nix-shell and run `fac` (format and check).

```sh
stylua lua/ && luacheck lua/ && busted --verbose
```

## Inspiration

### Clipboard harmonization

- [Clipboard integration between tmux, nvim, zsh, x11, across SSH sessions](https://blog.landofcrispy.com/index.php/2021/01/06/clipboard-integration-between-tmux-nvim-zsh-x11-across-ssh-sessions/)
- [Everything you need to know about Tmux copy paste - Ubuntu](http://www.rushiagr.com/blog/2016/06/16/everything-you-need-to-know-about-tmux-copy-pasting-ubuntu/)

### Navigation & resizing

- [better-vim-tmux-resizer](https://github.com/RyanMillerC/better-vim-tmux-resizer)
- [Navigator.nvim](https://github.com/numToStr/Navigator.nvim)
- [vim-tmux-navigator](https://github.com/christoomey/vim-tmux-navigator)
- [pogyomo/submode.nvim](https://github.com/pogyomo/submode.nvim)

The following content is no longer fully compliant with the current status. However, we keep it here for reference for those who are interested.

![dependabot](https://img.shields.io/badge/dependabot-enabled-025e8c?logo=Dependabot)
[![ci](https://github.com/aserowy/tmux.nvim/actions/workflows/ci.yaml/badge.svg)](https://github.com/aserowy/tmux.nvim/actions/workflows/ci.yaml)
[![coverage](https://coveralls.io/repos/github/aserowy/tmux.nvim/badge.svg?branch=main)](https://coveralls.io/github/aserowy/tmux.nvim?branch=main)

## Animations of part of the features

1.1. <details><summary>Normal yanking will sync the content from nvim to tmux </summary>

<a href="https://user-images.githubusercontent.com/8199164/124225235-5f984200-db07-11eb-9cff-ab73be12b4b1.mp4"></a>
</details>

1.2. <details><summary>Navigating between nvim and tmux panes with the same key bindings </summary>

<a href="https://user-images.githubusercontent.com/8199164/122721161-a026ce80-d270-11eb-9a27-2beff9910e69.mp4"></a>
</details>

1.3. <details><summary>Resizing nvim splits and tmux panes with the same key bindings </summary>

<a href="https://user-images.githubusercontent.com/8199164/122721182-a61caf80-d270-11eb-9f75-0dd6343c0cb7.mp4"></a>
</details>



