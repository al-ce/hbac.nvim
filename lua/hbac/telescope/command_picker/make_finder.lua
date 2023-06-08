local entry_display = require("telescope.pickers.entry_display")
local finders = require("telescope.finders")

local M = {}

M.make_finder = function(opts)
	M.finder_opts = opts
	local hbac_config = require("hbac.setup").opts
	local displayer = entry_display.create({
		items = {
			{ remaining = true },
		},
	})
	return finders.new_table({
		results = vim.tbl_keys(hbac_config.storage),
		entry_maker = function(entry)
			return {
				value = entry,
				display = function()
					return displayer({
						{ entry, "TelescopeResultsIdentifier" },
					})
				end,
				ordinal = entry,
			}
		end,
	})
end

return M
