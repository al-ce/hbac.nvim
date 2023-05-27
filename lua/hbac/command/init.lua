local subcommands = require("hbac.command.subcommands")
local hbac_notify = require("hbac.utils").hbac_notify


local M = {
	subcommands = {},
}

M.subcommands.close_unpinned = function()
	subcommands.close_unpinned()
	hbac_notify("Closed unpinned buffers", "info")
end

M.subcommands.toggle_pin = function()
	local bufnr, pinned_state = subcommands.toggle_pin()
	hbac_notify(bufnr .. " " .. pinned_state, "info")
end

M.subcommands.pin_all = function()
	subcommands.pin_all()
	hbac_notify("Pinned all buffers", "info")
end

M.subcommands.unpin_all = function()
	subcommands.unpin_all()
	hbac_notify("Unpinned all buffers", "info")
end

M.subcommands.toggle_autoclose = function()
	local autoclose_state = subcommands.toggle_autoclose() and "enabled" or "disabled"
	hbac_notify("Autoclose " .. autoclose_state, "info")
end

M.subcommands.telescope = function(opts)
	local hbac_telescope = require("hbac.telescope")
	if not hbac_telescope then
		return
	end
	hbac_telescope.pin_picker(opts)
end

M.vim_cmd_name = "Hbac"

M.vim_cmd_func = function(arg)
	if M.subcommands[arg] then
		M.subcommands[arg]()
	else
		hbac_notify("Unknown command: " .. arg, "warn")
	end
end

M.vim_cmd_opts = {
	nargs = 1,
	complete = function()
		return { unpack(vim.tbl_keys(M.subcommands)) }
	end,
}

return M
