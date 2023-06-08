local hbac_state = require("hbac.state")

local M = {}

M.buf_autoclosable = function(bufnr)
	local current_buf = vim.api.nvim_get_current_buf()
	if hbac_state.is_pinned(bufnr) or bufnr == current_buf then
		return false
	end
	local buffer_windows = vim.fn.win_findbuf(bufnr)
	local hbac_config = require("hbac.setup").opts
	if #buffer_windows > 0 and not hbac_config.close_buffers_with_windows then
		return false
	end
	return true
end

M.get_listed_buffers = function()
	return vim.tbl_filter(function(bufnr)
		return vim.api.nvim_buf_get_option(bufnr, "buflisted")
	end, vim.api.nvim_list_bufs())
end

M.get_listed_bufs_pinned_states = function()
	local listed_bufs_pinned_states = {}
	local listed_bufnrs = M.get_listed_buffers()
	local pinned_buffers = hbac_state.pinned_buffers
	for _, bufnr in ipairs(listed_bufnrs) do
		local fullpath = vim.fn.expand("#" .. tostring(bufnr) .. ":p")
		local is_pinned = pinned_buffers[bufnr] == true
		listed_bufs_pinned_states[fullpath] = {
			bufnr = bufnr,
			is_pinned = is_pinned,
		}
	end
	return listed_bufs_pinned_states
end

M.most_recent_buf = function(bufnrs)
	local most_recently_used = -1
	local most_recently_used_bufnr = nil
	for _, bufnr in ipairs(bufnrs) do
		local lastused = vim.fn.getbufinfo(bufnr)[1].lastused
		if lastused > most_recently_used then
			most_recently_used = lastused
			most_recently_used_bufnr = bufnr
		end
	end
	return most_recently_used_bufnr
end

M.get_pin_icon = function(bufnr)
	local hbac_config = require("hbac.setup").opts
	local pin_icons = hbac_config.telescope.pin_picker.pin_icons
	local is_pinned = hbac_state.is_pinned(bufnr)
	local pin_icon = is_pinned and pin_icons.pinned[1] or pin_icons.unpinned[1]
	local pin_icon_hl = is_pinned and pin_icons.pinned.hl or pin_icons.unpinned.hl
	return pin_icon, pin_icon_hl
end

M.hbac_notify = function(message, level)
	local hbac_config = require("hbac.setup").opts
	if hbac_config.notify then
		vim.notify(message, level or "info", { title = "Hbac" })
	end
end

M.set_notify = function(notify)
	local hbac_config = require("hbac.setup").opts
	hbac_config.notify = notify
end

return M
