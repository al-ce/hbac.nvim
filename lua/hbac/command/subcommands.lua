local autocommands = require("hbac.autocommands")
local hbac_state = require("hbac.state")
local hbac_utils = require("hbac.utils")
local hbac_notify = require("hbac.utils").hbac_notify

local M = {}

local set_all = function(pin_value)
	local buflist = hbac_utils.get_listed_buffers()
	for _, bufnr in ipairs(buflist) do
		hbac_state.pinned_buffers[bufnr] = pin_value
	end
end

M.close_unpinned = function()
	local buflist = hbac_utils.get_listed_buffers()
	for _, bufnr in ipairs(buflist) do
		if hbac_utils.buf_autoclosable(bufnr) then
			local hbac_config = require("hbac.setup").opts
			hbac_config.close_command(bufnr)
		end
	end
	hbac_notify("Closed unpinned buffers")
end

M.toggle_pin = function()
	local bufnr = vim.api.nvim_get_current_buf()
	local pinned_state = hbac_state.toggle_pin(bufnr) and "pinned" or "unpinned"
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
	hbac_state.autoclose_enabled = not hbac_state.autoclose_enabled
	if hbac_state.autoclose_enabled then
		autocommands.autoclose.setup()
	else
		autocommands.autoclose.disable()
	end
	local autoclose_state = hbac_state.autoclose_enabled and "enabled" or "disabled"
	hbac_notify("Autoclose " .. autoclose_state)
end

M.pin_picker = function(opts)
	local pin_picker = require("hbac.telescope.pin_picker")
	if not pin_picker then
		return
	end
	pin_picker.pin_picker(opts)
end

M.store_pinned_bufs = function()
	local store_pinned_bufs = require("hbac.storage").store_pinned_bufs
	store_pinned_bufs()
end

M.storage_picker = function(opts)
	local storage_picker = require("hbac.telescope.storage_picker")
	if not storage_picker then
		return
	end
	storage_picker.storage_picker(opts)
end

M.toggle_notify = function()
	local hbac_config = require("hbac.setup").opts
	hbac_config.notify = not hbac_config.notify
	local notify_state = hbac_config.notify and "enabled" or "disabled"
	vim.notify("Notifications " .. notify_state, "info", { title = "Hbac" })
end

return M
