local options  = require("tmux.configuration.options")
local keymaps  = require("tmux.keymaps")
local log      = require("tmux.log")
local tmux     = require("tmux.wrapper.tmux")

local function rtc(str)
    return vim.api.nvim_replace_termcodes(str, true, true, true)
end

local function sync_register(index, buffer_name)
    --  vim.print('buffer_name: ' .. buffer_name)
    if buffer_name == nil or buffer_name == "" then return end
    vim.fn.setreg(index, tmux.get_buffer(buffer_name))
end

local function sync_unnamed_register(buffer_name)
    if buffer_name ~= nil and buffer_name ~= "" then
        sync_register("@", buffer_name)
    end
end

local function sync_registers(passed_key)
    --  if type(passed_key) ~= "string" then return end
    if type(passed_key) ~= "string" then
        --  print("passed_key",  vim.inspect(passed_key))
        --  print("vim.v.event", vim.inspect(vim.v.event))
        return
    else
        log.debug(string.format("sync_registers: %s", tostring(passed_key)))
    end

    local ignore_buffers  = options.copy_sync.ignore_buffers
    local offset          = options.copy_sync.register_offset

    log.debug("ignore_buffers: ", ignore_buffers)

    local first_buffer_name = ""
    for k, v in ipairs(tmux.get_buffer_names()) do
        log.debug("buffer to sync: ", v)
        if ignore_buffers ~= nil and not ignore_buffers[v] then
            log.debug("buffer is syncing: ", v)
            if k == 1 then
                first_buffer_name = v
            end
            if k >= 11 - offset then
                break
            end
            sync_register(tostring(k - 1 + offset), v)
        end
    end

    if options.copy_sync.sync_unnamed then
        sync_unnamed_register(first_buffer_name)
    end

    if passed_key ~= nil and passed_key ~= "" then
        return rtc(passed_key)
    end
end

local function resolve_content(regtype, regcontents)
    local result = ""
    for index, value in ipairs(regcontents) do
        if index > 1 then
            result = result .. "\n"
        end
        result = result .. value
    end

    if regtype == "V" then
        result = result .. "\n"
    end

    return result
end

local function post_yank(content)
    if content.regname == nil then return end

    if content.regcontents == nil or content.regcontents == "" then
        return
    end

    if content.operator ~= "y" and not options.copy_sync.sync_deletes then
        return
    end

    local buffer_content = resolve_content(content.regtype, content.regcontents)
    --  vim.print('buffer_content: ' .. buffer_content)
    log.debug(buffer_content)

    tmux.set_buffer(buffer_content, options.copy_sync.redirect_to_clipboard)
end

local M = {
    sync_registers = sync_registers,
    post_yank      = post_yank,
}

function M.setup()
    if not tmux.is_tmux or not options.copy_sync.enable then
        return
    end

    if options.copy_sync.sync_registers then

        vim.api.nvim_create_autocmd({ "TextYankPost" }, {
            group    = vim.api.nvim_create_augroup("tmux_text_yank_post", { clear = true }),
            pattern  = { "*" },
            callback = function()
                --  [TextYankPost not setting v:event key regcontents (nor any other keys for TextYankPost) #2535](https://github.com/nvim-tree/nvim-tree.lua/issues/2535)
                post_yank(vim.v.event)
            end,
        })

        vim.api.nvim_create_autocmd({ "CmdwinEnter" }, {
            group    = vim.api.nvim_create_augroup("tmux_cmdwin_enter", { clear = true }),
            pattern  = { ":" },
            callback = sync_registers,
        })

        vim.api.nvim_create_autocmd({ "CmdlineEnter", "VimEnter" }, {
            group    = vim.api.nvim_create_augroup("tmux_sync_registers", { clear = true }),
            pattern  = { "*" },
            callback = sync_registers,
        })

        _G.tmux = {
            sync_registers = sync_registers,
            post_yank      = post_yank,
        }

        keymaps.register("n", {
            ['"'] = [[v:lua.tmux.sync_registers('"')]],
            ["p"] = [[v:lua.tmux.sync_registers('p')]],
            ["P"] = [[v:lua.tmux.sync_registers('P')]],
        }, {
            expr     = true,
            noremap  = true,
        })

        --  double C-r to prevent injection:
        --  https://vim.fandom.com/wiki/Pasting_registers#In_insert_and_command-line_modes
        keymaps.register("i", {
            ["<C-r>"] = [[v:lua.tmux.sync_registers("<C-r><C-r>")]],
        }, {
            expr     = true,
            noremap  = true,
        })

        keymaps.register("c", {
            ["<C-r>"] = [[v:lua.tmux.sync_registers("<C-r><C-r>")]],
        }, {
            expr     = true,
            noremap  = true,
        })
    end

    if options.copy_sync.sync_clipboard then
        vim.cmd[[
        if exists('g:clipboard')
            :unlet g:clipboard
        endif
        ]]
        vim.g.clipboard = {
            name = "tmuxclipboard",
            copy = {
				--  https://github.com/neovim/neovim/blob/master/runtime/autoload/provider/clipboard.vim
                ["+"] = "tmux load-buffer -w -", --  tmux 3.2 and later
                ["*"] = "tmux load-buffer -w -", --  tmux 3.2 and later
            },
            paste = {
                ["+"] = "tmux save-buffer -",
                ["*"] = "tmux save-buffer -",
            },
        }
        vim.cmd[[
        if exists('g:loaded_clipboard_provider')
            :unlet g:loaded_clipboard_provider
            " :source  autoload/provider/clipboard.vim
            :source  /usr/share/nvim/runtime/autoload/provider/clipboard.vim
            " :runtime autoload/provider/clipboard.vim
            :runtime /usr/share/nvim/runtime/autoload/provider/clipboard.vim
        endif
        ]]
    end
end

return M
