-- TODO: check telescope dependencies

local conf = require("telescope.config").values
local pickers = require("telescope.pickers")

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
			attach_mappings = function(_, map)
				local hbac_storage_actions = require("hbac.storage.actions")
				map("i", "<CR>", hbac_storage_actions.hbac_open_stored_pins)
				map("n", "<CR>", hbac_storage_actions.hbac_open_stored_pins)
				return true
			end,
		})
		:find()
end

return M
