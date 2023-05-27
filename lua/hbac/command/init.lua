local subcommands = require("hbac.command.subcommands")
local hbac_notify = require("hbac.utils").hbac_notify

local M = {}

M.vim_cmd_name = "Hbac"

M.vim_cmd_func = function(arg)
	if subcommands[arg] then
		subcommands[arg]()
	else
		hbac_notify("Unknown command: " .. arg, "warn")
	end
end

M.vim_cmd_opts = {
	nargs = 1,
	complete = function()
		return { unpack(vim.tbl_keys(subcommands)) }
	end,
}

return M
