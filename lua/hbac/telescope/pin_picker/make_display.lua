local hbac_utils = require("hbac.utils")
local hbac_telescope_utils = require("hbac.telescope.telescope_utils")
local entry_display = require("telescope.pickers.entry_display")

local M = {}

M.display = function(entry)
	local bufnr, bufname = entry.value, entry.ordinal
	local displayer = entry_display.create({
		separator = " ",
		items = {
			{ width = 2 },
			{ width = 2 },
			{ remaining = true },
		},
	})

	return displayer({
		{ hbac_utils.get_pin_icon(bufnr) },
		{ hbac_telescope_utils.get_devicon(bufname) },
		hbac_telescope_utils.get_display_text(bufname),
	})
end

return M
