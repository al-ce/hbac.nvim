local check_dependencies = require("hbac.telescope.telescope_utils").check_dependencies
if not check_dependencies() then
	return false
end

local pickers = require("telescope.pickers")
local telescope_conf = require("telescope.config").values

local M = {}

M.pin_picker = function(opts)
	local attach_mappings = require("hbac.telescope.pin_picker.attach_mappings")
	local make_finder = require("hbac.telescope.pin_picker.make_finder")
	opts = opts or {}
	pickers
		.new(opts, {
			prompt_title = "Hbac Pin States",
			finder = make_finder.make_finder(opts),
			sorter = telescope_conf.generic_sorter(opts),
			attach_mappings = attach_mappings.attach_mappings,
			previewer = telescope_conf.file_previewer(opts),
			default_selection_index = make_finder.default_selection_idx,
		})
		:find()
end

return M
