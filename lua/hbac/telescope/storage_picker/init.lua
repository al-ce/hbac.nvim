local check_dependencies = require("hbac.telescope.telescope_utils").check_dependencies
if not check_dependencies() then
	return false
end

local conf = require("telescope.config").values
local pickers = require("telescope.pickers")

local attach_mappings = require("hbac.telescope.storage_picker.attach_mappings")

local M = {}

M.storage_picker = function(opts)
	opts = opts or {}
	local finder = require("hbac.telescope.storage_picker.make_finder")
	local previewer = require("hbac.telescope.storage_picker.previewer")
	pickers
		.new(opts, {
			prompt_title = "Hbac: Stored Pins",
			finder = finder.make_finder(),
			previewer = previewer.previewer(),
			sorter = conf.generic_sorter(opts),
			attach_mappings = attach_mappings.attach_mappings,
		})
		:find()
end

return M
