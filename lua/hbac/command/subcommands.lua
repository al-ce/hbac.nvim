local autocommands = require("hbac.autocommands")
local hbac_config = require("hbac.setup").opts
local state = require("hbac.state")
local utils = require("hbac.utils")
local hbac_notify = require("hbac.utils").hbac_notify

local M = {}

local set_all = function(pin_value)
	local buflist = utils.get_listed_buffers()
	for _, bufnr in ipairs(buflist) do
		state.pinned_buffers[bufnr] = pin_value
	end
end

M.close_unpinned = function()
	local buflist = utils.get_listed_buffers()
	for _, bufnr in ipairs(buflist) do
		if utils.buf_autoclosable(bufnr) then
			hbac_config.close_command(bufnr)
		end
	end
	hbac_notify("Closed unpinned buffers")
end

M.toggle_pin = function()
	local bufnr = vim.api.nvim_get_current_buf()
	local pinned_state = state.toggle_pin(bufnr) and "pinned" or "unpinned"
	hbac_notify(bufnr .. " " .. pinned_state)
	return bufnr, pinned_state
end

M.pin_all = function()
	set_all(true)
	hbac_notify("Pinned all buffers")
end

M.unpin_all = function()
	set_all(false)
	hbac_notify("Unpinned all buffers")
end

M.toggle_autoclose = function()
	state.autoclose_enabled = not state.autoclose_enabled
	if state.autoclose_enabled then
		autocommands.autoclose.setup()
	else
		autocommands.autoclose.disable()
	end
	local autoclose_state = state.autoclose_enabled and "enabled" or "disabled"
	hbac_notify("Autoclose " .. autoclose_state)
end

M.telescope = function(opts)
	local hbac_telescope = require("hbac.telescope")
	if not hbac_telescope then
		return
	end
	hbac_telescope.pin_picker(opts)
end

M.store_pinned_bufs = function()
	local storage = require("hbac.storage")
	storage.store_pinned_bufs()
end

return M
