local api = vim.api

local keymaps = {}
keymaps.register = function(scope, mappings, options)
    local opts
    if options == nil then
        opts = {
            nowait   = true,
            silent   = true,
            noremap  = true,
        }
    else
        opts = options
    end

    for key, value in pairs(mappings) do
        api.nvim_set_keymap(scope, key, value, opts)
    end
end

function keymaps.map(mode, lhs, rhs, opts)
	local options = { }
	if opts then
		options = vim.tbl_extend("force", options, opts)
	end
	--  local original_definition =
	--  vim.api.nvim_exec("call maparg('" .. lhs .. "', '" ..  mode .. "', " .. "v:false" .. ")", "false")
	--  if original_definition then
	--      vim.cmd(mode .. "unmap " .. lhs)
	--  end
	--
	--  if (type(rhs) == "function") then
		vim.keymap.set(mode, lhs, rhs, options)
	--  elseif (type(rhs) == "string") then
	--  Does not work on most mappings
	--      vim.api.nvim_set_keymap(mode, lhs, rhs, options)
	--  end
end

return keymaps
