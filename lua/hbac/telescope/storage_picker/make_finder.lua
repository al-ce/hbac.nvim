local entry_display = require("telescope.pickers.entry_display")
local finders = require("telescope.finders")
local hbac_storage_utils = require("hbac.storage.utils")

local M = {}

M.make_finder = function(opts)
	M.finder_opts = opts
	local pin_storage = hbac_storage_utils.get_pin_storage() or {}

	local pin_storage_keys = vim.tbl_keys(pin_storage)
	table.sort(pin_storage_keys, function(a, b)
		local pin_session_a = pin_storage[a]
		local pin_session_b = pin_storage[b]
		return pin_session_a.timestamp > pin_session_b.timestamp
	end)

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

	local entry_maker = function(entry)
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
			ordinal = entry,
			stored_pins = pin_session.stored_pins,
			timestamp = pin_session.timestamp,
		}
	end

	return finders.new_table({
		results = pin_storage_keys,
		entry_maker = entry_maker,
	})
end

return M
