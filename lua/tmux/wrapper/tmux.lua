
local function file_exists(name)
    local f = io.open(name, "r")
    if f ~= nil then io.close(f) return true else return false end
end

local vim = vim

local log = require("tmux.log")

local tmux_directions = {
    h = "L",
    j = "D",
    k = "U",
    l = "R",
}

local function get_tmux()
    return os.getenv("TMUX")
end

local function get_tmux_pane()
    return os.getenv("TMUX_PANE")
end

local function get_socket()
    return vim.split(get_tmux(), ',')[1]
end

local function execute(arg, pre, raw)
    local command = string.format("%s /usr/bin/tmux -S '%s' %s", pre or "", get_socket(), arg)

    local handle = assert(io.popen(command), string.format("unable to execute: [%s]", command))
    local result = assert(handle:read('*all'))
    handle:close()

    if raw then return result end

    result = string.gsub(result, '^%s+',    '')
    result = string.gsub(result, '%s+$',    '')
    result = string.gsub(result, '[\n\r]+', ' ')

    return result
end

local function get_version()
    local result = execute('-V')
    if result == nil then return 0.0 end
    local version = result:sub(result:find(" ") + 1)

    return version:gsub("[^%.%w]", "")
end

local M = {
    is_tmux        = false,
    get_tmux       = get_tmux,
    get_version    = get_version,
    execute        = execute,
    get_tmux_pane  = get_tmux_pane,
    file_exists    = file_exists,
}

function M.setup()
    M.is_tmux = get_tmux() ~= nil

    log.debug(M.is_tmux)

    if not M.is_tmux then
        return false
    end

    M.version = get_version()

    log.debug(M.version)

    vim.api.nvim_create_autocmd({ 'VimEnter', 'VimResume', 'FocusGained', 'BufEnter' }, {
        group = vim.api.nvim_create_augroup("tmux_is_vim_vimenter", { clear = true }),
        pattern = { "*" },
        callback = function()
            execute(string.format("set-option -p -t '%s' '@%s' %s", get_tmux_pane(), 'is-vim', 'on'))
        end,
    })

    vim.api.nvim_create_autocmd({ "VimLeave", 'VimSuspend' }, {
        group = vim.api.nvim_create_augroup("tmux_is_vim_vimleave", { clear = true }),
        pattern = { "*" },
        callback = function(args)
            execute(string.format("set-option -p -u -t '%s' '@%s'", get_tmux_pane(), 'is-vim'))
        end,
    })

    --  vim.print('autocmd set')

    return true
end

function M.change_pane(direction)
    execute(string.format("select-pane -t '%s' -%s", get_tmux_pane(), tmux_directions[direction]))
end

function M.get_buffer(name)
    return execute(string.format("show-buffer -b '%s'", name))
end

function M.get_buffer_names()
    local buffers = execute([[ list-buffers -F '#{buffer_name}' ]], '', true)

    local result = {}
    for line in buffers:gmatch("([^\n]+)\n?") do
        table.insert(result, line)
    end

    return result
end

function M.get_current_pane_id()
    return tonumber(get_tmux_pane():sub(2))
end

function M.get_window_layout()
    return execute("display-message -p '#{window_layout}'")
end

function M.is_zoomed()
    return execute("display-message -p '#{window_zoomed_flag}'"):find("1")
end

function M.resize(direction, step)
    execute(string.format("resize-pane -t '%s' -%s %d", get_tmux_pane(), tmux_directions[direction], step))
end

function M.set_buffer(content, sync_clipboard)
    content = content:gsub("\\", "\\\\")
    content = content:gsub('"',  '\\"')
    content = content:gsub("`",  "\\`")
    content = content:gsub("%$", "\\$")

    if sync_clipboard ~= nil and sync_clipboard then
        execute("load-buffer -w -", string.format('printf "%%s" "%s" | ', content))
    else
        execute("load-buffer -",    string.format('printf "%%s" "%s" | ', content))
    end
    local display_value = execute([[show-option -gqv '@display-value']])
    --  local display_value_with_new_line = execute([[show-option -gqv '@display-value']], '', true)
    --  if display_value_with_new_line ~= "" then --  always is true
    if display_value ~= "" then
        --  log.debug('@display-value: "' .. display_value_with_new_line .. '"')
        --  print('@display-value', '"' .. display_value_with_new_line .. '"')
        log.debug('@display-value [no new line]: "' .. display_value .. '"')
        --  print('@display-value [no new line]', '"' .. display_value .. '"')
        execute("save-buffer - | " .. execute([[display -p '#{copy-command}']], '', true))
    end
end

return M
