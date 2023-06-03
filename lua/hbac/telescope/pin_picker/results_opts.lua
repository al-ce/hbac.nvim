-- NOTE These are copied/modified from telescope.builtin.internal.buffers

local hbac_utils = require("hbac.utils")

local M = {}

M.filter_bufnrs_by_opts = function(opts, bufnrs)
	local filter = vim.tbl_filter
	bufnrs = filter(function(b)
		if
			(opts.show_all_buffers == false and not vim.api.nvim_buf_is_loaded(b))
			or (opts.ignore_current_buffer and b == hbac_utils.most_recent_buf(bufnrs))
			or (opts.cwd_only and not string.find(vim.api.nvim_buf_get_name(b), vim.loop.cwd(), 1, true))
			or (opts.cwd_only and opts.cwd and not string.find(vim.api.nvim_buf_get_name(b), opts.cwd, 1, true))
		then
			return false
		end
		return true
	end, bufnrs)

	if not next(bufnrs) then
		return {}
	end
	if opts.sort_mru then
		table.sort(bufnrs, function(a, b)
			return vim.fn.getbufinfo(a)[1].lastused > vim.fn.getbufinfo(b)[1].lastused
		end)
	end

	return bufnrs
end

M.set_default_select_idx = function(opts, bufnrs)
	local buffers = {}
	local default_selection_idx = 1
	for _, bufnr in ipairs(bufnrs) do
		local flag = bufnr == vim.fn.bufnr("") and "%" or (bufnr == vim.fn.bufnr("#") and "#" or " ")
		if opts.sort_lastused and not opts.ignore_current_buffer and flag == "#" then
			default_selection_idx = 2
		end
		local element = {
			bufnr = bufnr,
			flag = flag,
			info = vim.fn.getbufinfo(bufnr)[1],
		}
		if opts.sort_lastused and (flag == "#" or flag == "%") then
			local idx = ((buffers[1] ~= nil and buffers[1].flag == "%") and 2 or 1)
			table.insert(buffers, idx, element)
		else
			table.insert(buffers, element)
		end
	end
	return default_selection_idx
end

return M
