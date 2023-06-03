local finders = require("telescope.finders")
local results_opts = require("hbac.telescope.pin_picker.results_opts")

local filter_bufnrs = results_opts.filter_bufnrs_by_opts
local set_default_select_idx = results_opts.set_default_select_idx

local M = {}

M.finder_opts = {}
M.default_selection_idx = 1

local function get_entries(opts)
	local make_display = require("hbac.telescope.pin_picker.make_display")
	local display = make_display.display
	local utils = require("hbac.utils")

	local bufnrs = utils.get_listed_buffers()
	bufnrs = filter_bufnrs(opts, bufnrs)

	M.default_selection_idx = set_default_select_idx(opts, bufnrs)

	local entries = {}
	for _, bufnr in ipairs(bufnrs) do
		local bufname = vim.api.nvim_buf_get_name(bufnr)
		table.insert(entries, {
			filename = bufname,
			display = display, -- if we implement bufnrs in display, pass opts.bufnr_width
			value = bufnr,
			ordinal = bufname,
		})
	end
	return entries
end

M.make_finder = function(opts)
	M.finder_opts = opts
	return finders.new_table({
		results = get_entries(opts),
		entry_maker = function(entry)
			return {
				filename = entry.filename,
				value = entry.value,
				display = entry.display,
				ordinal = entry.ordinal,
				path = entry.ordinal,
			}
		end,
	})
end

return M
