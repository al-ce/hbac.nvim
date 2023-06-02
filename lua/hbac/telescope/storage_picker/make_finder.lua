local entry_display = require("telescope.pickers.entry_display")
local finders = require("telescope.finders")
local hbac_storage_utils = require("hbac.storage.utils")

local M = {}

M.make_finder = function()
	local pin_storage = hbac_storage_utils.get_pin_storage() or {}

	local function get_pin_count(pin_session)
		local stored_pins = pin_session["stored_pins"]
		return #stored_pins
	end

	local displayer = entry_display.create({
		separator = " ",
		items = {
			{ width = 10 },
			{ width = 2 },
			{ remaining = true },
		},
	})

	return finders.new_table({
		results = vim.tbl_keys(pin_storage),
		entry_maker = function(entry)
			local pin_session = pin_storage[entry]
			return {
				value = entry,
				display = function()
					local pin_count = get_pin_count(pin_session)
					local proj_root = pin_session["proj_root"]
					return displayer({
						{ entry, "TelescopeResultsIdentifier" },
						{ pin_count, "TelescopeResultsNumber" },
						proj_root,
					})
				end,
				-- TODO: sort by timestamp
				ordinal = entry,
				stored_pins = pin_session.stored_pins,
				timestamp = pin_session.timestamp,
			}
		end,
	})
end

return M
