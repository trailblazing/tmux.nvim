local config      = require("tmux.configuration")
local copy        = require("tmux.copy")
local log         = require("tmux.log")
local navigation  = require("tmux.navigation")
local resize      = require("tmux.resize")
local prefix      = require("tmux.prefix")
local tmux        = require("tmux.wrapper.tmux")

local options = {
    copy_sync = {
        enable = true,
    },
    tmux    = {
        conf    = os.getenv("HOME") .. "/.tmux.conf",
        header  = os.getenv("XDG_CONFIG_HOME") .. "/tmux/header.conf",
    },
    prefix  = {
        conf    = os.getenv("XDG_CONFIG_HOME") .. "/tmux/prefix.conf",
        wincmd  = os.getenv("XDG_CONFIG_HOME") .. "/tmux/wincmd.conf",
        prefix_background   = "#00d7d7",
        normal_background   = "colour003",
        prefix_bg_on_light  = "#d7d700",
        normal_bg_on_light  = "colour003",
    },
    navigation = {
        conf    = os.getenv("XDG_CONFIG_HOME") .. "/tmux/navigation.conf",
        enable_default_keybindings = true,
    },
    resize = {
        conf    = os.getenv("XDG_CONFIG_HOME") .. "/tmux/resize.conf",
        enable_default_keybindings = true,
    },
    logging = {
        file    = "debug",
    },
}

local M = {
    move_left       = navigation.to_left,
    move_bottom     = navigation.to_bottom,
    move_top        = navigation.to_top,
    move_right      = navigation.to_right,

    post_yank       = copy.post_yank,
    sync_registers  = copy.sync_registers,

    resize_left     = resize.to_left,
    resize_bottom   = resize.to_bottom,
    resize_top      = resize.to_top,
    resize_right    = resize.to_right,
}

local function script_path()
    local seperator = os.tmpname():sub(1,1)
    local filename = debug.getinfo(2, "S").source:sub(2)
    local dir_current = filename:match("(.*[/\\])") --  or "./"
    if dir_current == nill or dir_current == "" then
        dir_current = "." .. seperator
    end
    local tmux_dir = dir_current .. '..' .. seperator .. '..' .. seperator .. 'tmux'
    return tmux_dir
end

--  Merged logging into options for compatibility reasons with lazy.nvim
function M.setup(opts) --  function M.setup(opts, logging)
    if opts.logging == nil or opts.logging.file == "disabled" and opts.logging.file == "disabled" then
        print = function() end
    end
    --  print("init:package.path", serialize(package.path))
    --  print("init:logging", vim.inspect(logging))
    --  print("init:opts",    vim.inspect(opts))

    --  vim.notify(script_path())
        print("script_path()", script_path())
    --  os.execute("sh -c '" .. script_path() .. "../../install'")

    if tmux.file_exists(opts.tmux.conf) then
        print("File exists", opts.tmux.conf)
    else
        print("File does not exist", opts.tmux.conf)
        vim.notify("File does not exist: " .. opts.tmux.conf)
    end
    if tmux.file_exists(opts.tmux.header) then
        print("File exists", opts.tmux.header)
    else
        os.execute('ln -sf ' .. script_path() .. 'header.conf ' .. opts.tmux.header)
    end
    if tmux.file_exists(opts.prefix.conf) then
        print("File exists", opts.prefix.conf)
    else
        os.execute('ln -sf ' .. script_path() .. 'prefix.conf ' .. opts.prefix.conf)
    end
    if tmux.file_exists(opts.prefix.wincmd) then
        print("File exists", opts.prefix.wincmd)
    else
        os.execute('ln -sf ' .. script_path() .. 'wincmd.conf ' .. opts.prefix.wincmd)
    end
    if tmux.file_exists(opts.navigation.conf) then
        print("File exists", opts.navigation.conf)
    else
        os.execute('ln -sf ' .. script_path() .. 'navigation.conf ' .. opts.navigation.conf)
    end
    if tmux.file_exists(opts.resize.conf) then
        print("File exists", opts.resize.conf)
    else
        os.execute('ln -sf ' .. script_path() .. 'resize.conf ' .. opts.resize.conf)
    end


    if opts then
        for k, v in pairs(opts) do
            options[k] = v
        end
    end

    log.setup(options.logging or {})

    log.debug("setup tmux wrapper")
    local is_inside_tmux = tmux.setup(options)

    if is_inside_tmux then
        log.debug("setup config")
        config.setup(options) --  config.setup(options, logging)

        log.debug("setup copy")
        copy.setup()

        log.debug("setup navigate")
        navigation.setup()

        log.debug("setup resize")
        resize.setup()

        log.debug("setup prefix")
        prefix.setup()
    end
end

return M
