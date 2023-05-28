-- TODO: check telescope dependencies

local conf = require("telescope.config").values
local pickers = require("telescope.pickers")

local attach_mappings = require("hbac.storage.attach_mappings")

local M = {}

M.stored_pins_picker = function(opts)
	opts = opts or {}
	local finder = require("hbac.storage.make_finder")
	local previewer = require("hbac.storage.previewer")
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
