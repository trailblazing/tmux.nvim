# tmux.nvim

Automatic clipboard synchronization between nvim and tmux is an important feature for pure tty editing.

Normally, one doesn't need ctrl-shift-{c, v} when coding even in a GUI evironment, nor does one need the aid of a mouse.

There is vim-tmux-clipboard, but it's [different](https://github.com/trailblazing/dotconfig/blob/master/init/editor/nvim/lua/plugins/core.lua).

With the design and implementation of tmux.nvim,

1. One can copy content from mvim to the terminal in tmux without switching to tmux's copy mode.
This is very useful for complex and long texts.

2. Of course, with [<B>tmux's system clipboard settings</b>](https://github.com/trailblazing/dotconfig/blob/master/init/terminal/tmux.conf), one can copy content to the system clipboard
simultaneously in this combined environment without relying on the editor's association
with the system clipboard.

On NVIM v0.10.1, file /usr/share/nvim/runtime/autoload/provider/clipboard.vim has done most of the work.

We just need to stabilize the interface and working habits -- to manage interfaces in a structured way, so as not to get lost in the inevitable conflicting deatails of the code pile.

There are many ways to implement navigation and resizing -- this plugin is just one of the simplest one. This plugin
does not solve all related issues. For example the settings of prefix key and copy mode vary from person to person and
it is difficult to have a fixed pattern.

Based on the above scenario, I am glad to fork tmux.nvim.

I hope this interface remains stable. Of course, you are welcome to find bugs and improve it.


![dependabot](https://img.shields.io/badge/dependabot-enabled-025e8c?logo=Dependabot)
[![ci](https://github.com/aserowy/tmux.nvim/actions/workflows/ci.yaml/badge.svg)](https://github.com/aserowy/tmux.nvim/actions/workflows/ci.yaml)
[![coverage](https://coveralls.io/repos/github/aserowy/tmux.nvim/badge.svg?branch=main)](https://coveralls.io/github/aserowy/tmux.nvim?branch=main)

## Features

1. <details><summary>Normal yanking will sync the content from nvim to tmux </summary>

<a href="https://user-images.githubusercontent.com/8199164/124225235-5f984200-db07-11eb-9cff-ab73be12b4b1.mp4"></a>
</details>

2. <details><summary>Navigating between nvim and tmux panes with the same key bindings </summary>

<a href="https://user-images.githubusercontent.com/8199164/122721161-a026ce80-d270-11eb-9a27-2beff9910e69.mp4"></a>
</details>

3. <details><summary>Resizing nvim splits and tmux panes with the same key bindings </summary>

<a href="https://user-images.githubusercontent.com/8199164/122721182-a61caf80-d270-11eb-9f75-0dd6343c0cb7.mp4"></a>
</details>



## Installation

On NVIM v0.10.1 one needs this clipboard [setting](https://github.com/trailblazing/dotconfig/blob/master/init/editor/nvim/lua/config.lua).
```lua
vim.opt.clipboard = "unnamed"
vim.opt.clipboard = vim.opt.clipboard + "unnamedplus"
```
Install tmux.nvim with e.g. [lazy.nvim](https://github.com/folke/lazy.nvim):

[$XDG_CONFIG_HOME/nvim/lua/plugins/tmux.lua](https://github.com/trailblazing/dotconfig/blob/master/init/editor/nvim/lua/plugins/tmux.lua)


Tmux.nvim uses only `lua` API. If the default keybindings are not working , bind the following options to your liking.

```lua
return {
	"trailblazing/tmux.nvim",
	cond   = true,
	branch = 'main',
	event  = "TextYankPost",
	lazy   = true,
	config = function()
		opts    = {
			copy_sync = {
				enable          = true, -- default
				sync_clipboard  = true, -- default
				sync_registers  = true, -- default
				redirect_to_clipboard = false, -- default
			},
			navigation = {
				enable_default_keybindings = true, -- default
				cycle_navigation = true, -- default
			},
			resize = {
				enable_default_keybindings = true, -- default
			},
		}
		logging = {
			file    = "disabled", -- not default
			notify  = "disabled", -- not default
		},
		return require("tmux").setup(opts, logging)
	end
}
```
Besides the bindings in nvim you need to add configuration to [.tmux.conf](https://github.com/trailblazing/dotconfig/blob/master/init/terminal/tmux.conf).
```tmux
if -b '[ -e "$XDG_DATA_HOME/nvim/lazy/tmux.nvim/tmux.nvim.tmux" ]' {
  set-option -g @tmux-nvim-resize           true
  set-option -g @tmux-nvim-navigation-cycle true
  run -b '. $XDG_DATA_HOME/nvim/lazy/tmux.nvim/tmux.nvim.tmux'
  display -p "Using tmux.nvim \n@tmux-nvim-resize: #{@tmux-nvim-resize}\n@tmux-nvim-navigation-cycle: #{@tmux-nvim-navigation-cycle}\n[$copy_mode_key/Enter to quit the prompt]"
}

```
If you have no conflicting setup, this is all you need to install.

## Usage

Forget it. Focus on our thinking and coding. Every thing seems to be the same as before, you just maintain consistency and assimilate the unnecessary complexity between the layers of the software system -- forget the additional layers of the terminal, such as ctrl-shift sequence of operation details. and the complex operation of the mouse in the editing environment can also be abandoned.

## Requirements

- neovim >= 0.5

The plugin and [`.tmux.conf`](https://github.com/trailblazing/dotconfig/blob/master/init/terminal/tmux.conf) scripts are battle tested with

- tmux 3.2a
- POSIX shell -- The following line in our [.tmux.conf](https://github.com/trailblazing/dotconfig/blob/master/init/terminal/tmux.conf) gets all of the posix-shell script of the plugin
```
  run -b '. $XDG_DATA_HOME/nvim/lazy/tmux.nvim/tmux.nvim.tmux'
```

## Configuration

The config step is only necessary to overwrite configuration defaults.

The following defaults are given:

```lua
{
	copy_sync = {
		-- enables copy sync. by default, all registers are synchronized.
		-- to control which registers are synced, see the `sync_*` options.
		enable = true,

		-- ignore specific tmux buffers e.g. buffer0 = true to ignore the
		-- first buffer or named_buffer_name = true to ignore a named tmux
		-- buffer with name named_buffer_name :)
		ignore_buffers = { empty = false },

		-- TMUX >= 3.2: all yanks (and deletes) will get redirected to system
		-- clipboard by tmux
		redirect_to_clipboard = false,

		-- offset controls where register sync starts
		-- e.g. offset 2 lets registers 0 and 1 untouched
		register_offset = 0,

		-- overwrites vim.g.clipboard to redirect * and + to the system
		-- clipboard using tmux. If your keep nvim syncing directly to the system clipboard without using tmux,
		-- disable this option!
		sync_clipboard = true,

		-- synchronizes registers *, +, unnamed, and 0 till 9 with tmux buffers.
		sync_registers = true,

		-- syncs deletes with tmux clipboard as well, it is adviced to
		-- do so. Nvim does not allow syncing registers 0 and 1 without
		-- overwriting the unnamed register. Thus, ddp would not be possible.
		sync_deletes = true,

		-- syncs the unnamed register with the first buffer entry from tmux.
		sync_unnamed = true,
	},
	navigation = {
		-- cycles to opposite pane while navigating into the border
		cycle_navigation = true,

		-- enables default keybindings (C-hjkl) for normal mode
		enable_default_keybindings = true,

		-- prevents unzoom tmux when navigating beyond vim border
		persist_zoom = false,
	},
	resize = {
		-- enables default keybindings (A-hjkl) for normal mode
		enable_default_keybindings = true,

		-- sets resize steps for x axis
		resize_step_x = 5,

		-- sets resize steps for y axis
		resize_step_y = 2,
	}
}
```


### Copy sync

Copy sync uses tmux buffers as master clipboard for `*`, `+`, `unnamed`, and `0` - `9` registers. The sync does NOT rely on temporary files and works just with the given tmux API. Thus, making it less insecure :). The feature enables a nvim instace overarching copy/paste process! yank/dd in one nvim instance, switch to the second and p the copies/deletes.

If we do not sync clipboard with a standalone tmux, disable `sync_clipboard` to ensure nvim handles yanks and deletes alone.

This has some downsites, on really slow machines, calling registers or pasting will eventually produce minimal input lag by syncing registers in advance to ensure the correctness of state. To avoid this, disabling `sync_registers` will only redirect the `*` and `+` registers.

To redirect copies (and deletes) to clipboard, tmux must have the capability to do so. The plugin will just set -w on set-buffer. If your tmux need more configuration check out [tmux-yank](https://github.com/tmux-plugins/tmux-yank) for an easy setup.

Ignoring buffers must have the form of `buffer_name = true` to enable an unsorted list in lua. This enhances the performance of checks - if a buffer is ignored or not - meaningfull.

### Navigation

To enable cycle-free navigation beyond nvim, add the following to the [`~/.tmux.conf`](https://github.com/trailblazing/dotconfig/blob/master/init/terminal/tmux.conf):
```tmux
set -g @tmux-nvim-navigation-cycle true
```


It is important to note, that the bindings in nvim must match the defined bindings in tmux! Otherwise the pass through will not have the seamless effect!


Otherwise you can add:

```tmux
set -g @tmux-nvim-navigation-cycle false
```

To run custom bindings in nvim, make sure to set `enable_default_keybindings` to `false` in [tmux.lua](https://github.com/trailblazing/dotconfig/blob/master/init/editor/nvim/lua/plugins/tmux.lua). The following functions are used to navigate around windows and panes:

```lua
{
	[[<cmd>lua require("tmux").move_left()<cr>]],
	[[<cmd>lua require("tmux").move_bottom()<cr>]],
	[[<cmd>lua require("tmux").move_top()<cr>]],
	[[<cmd>lua require("tmux").move_right()<cr>]],
}
```

### Resize

Add the following bindings to the [`~/.tmux.conf`](https://github.com/trailblazing/dotconfig/blob/master/init/terminal/tmux.conf):

It is important to note, that the bindings in nvim must match the defined bindings in tmux! Otherwise the pass through will not have the seamless effect!

```tmux
  set-option -g @tmux-nvim-resize           true
```

To run custom bindings in nvim, make sure to set `enable_default_keybindings` to `false` in [tmux.lua](https://github.com/trailblazing/dotconfig/blob/master/init/editor/nvim/lua/plugins/tmux.lua). The following functions are used to resize windows:

```lua
{
	[[<cmd>lua require("tmux").resize_left()<cr>]],
	[[<cmd>lua require("tmux").resize_bottom()<cr>]],
	[[<cmd>lua require("tmux").resize_top()<cr>]],
	[[<cmd>lua require("tmux").resize_right()<cr>]],
}
```

## Tpm

If you prefer [tmux plugin manager](https://github.com/tmux-plugins/tpm), you can add the following plugin.

```tmux
set -g @plugin 'trailblazing/tmux.nvim'

run '~/.tmux/plugins/tpm/tpm'
```

Available options for the plugin and their defaults are (if you use the defaults, you don't need to manually write these options into tmux.conf):

```tmux

# navigation
set -g @tmux-nvim-navigation true
set -g @tmux-nvim-navigation-cycle true
set -g @tmux-nvim-navigation-keybinding-left  'C-h'
set -g @tmux-nvim-navigation-keybinding-down  'C-j'
set -g @tmux-nvim-navigation-keybinding-up    'C-k'
set -g @tmux-nvim-navigation-keybinding-right 'C-l'

# resize
set -g @tmux-nvim-resize true
set -g @tmux-nvim-resize-step-x 5
set -g @tmux-nvim-resize-step-y 2
set -g @tmux-nvim-resize-keybinding-left  'M-h'
set -g @tmux-nvim-resize-keybinding-down  'M-j'
set -g @tmux-nvim-resize-keybinding-up    'M-k'
set -g @tmux-nvim-resize-keybinding-right 'M-l'

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

