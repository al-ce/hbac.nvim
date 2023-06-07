local action_state = require("telescope.actions.state")
local hbac_telescope_utils = require("hbac.telescope.telescope_utils")
local execute_telescope_action = hbac_telescope_utils.execute_telescope_action

local M = {}

local hbac_recall_pin_picker = function()
	local make_finder = require("hbac.telescope.pin_picker.make_finder")
	local finder_opts = make_finder.finder_opts
	require("hbac.telescope.pin_picker").pin_picker(finder_opts)
end

local add_selected_bufs_to_storage_entry = function(keyname)
	local pin_storage = require("hbac.storage")
	local selected_bufs = M.selected_buffers
	for _, buf in ipairs(selected_bufs) do
		pin_storage.add_buf_to_entry(keyname, buf)
	end
end

local hbac_add_buf_to_storage_entry = function(prompt_bufnr)
	local picker = action_state.get_current_picker(prompt_bufnr)
	execute_telescope_action(picker, add_selected_bufs_to_storage_entry, "ordinal")
	local finder = require("hbac.telescope.storage_picker.make_finder")
	hbac_telescope_utils.refresh_picker(picker, finder.make_finder, M.pin_sorter_opts)
end

M.pin_sorter_opts = {
	prompt_title = "Hbac: Pin Sorter",
	results_title = "Storage Entries",
	layout_strategy = "horizontal",
	layout_config = {
		height = 0.2,
		width = 0.7,
		preview_width = 0.6,
	},
	borderchars = {
		{ "─", "│", "─", "│", "┌", "┐", "┘", "└" },
		preview = { "─", "│", "─", "│", "┌", "┐", "┘", "└" },
	},
	attach_mappings = function(_, map)
		map({ "n", "i" }, "<Esc>", hbac_recall_pin_picker)
		map({ "n", "i" }, "<CR>", hbac_add_buf_to_storage_entry)
		return true
	end,
}

M.hbac_add_buf_to_storage = function(prompt_bufnr)
	M.selected_buffers = {}
	local picker = action_state.get_current_picker(prompt_bufnr)

	local function insert_into_selected_buffers(bufnr)
		table.insert(M.selected_buffers, bufnr)
	end

	execute_telescope_action(picker, insert_into_selected_buffers)
	local hbac_pin_sorter = function()
		local opts = M.pin_sorter_opts
		require("hbac.telescope.storage_picker").storage_picker(opts)
	end
	hbac_pin_sorter()
end

return M
