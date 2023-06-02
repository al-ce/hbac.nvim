local hbac_storage_utils = require("hbac.storage.utils")
local hbac_telescope_utils = require("hbac.telescope.telescope_utils")
local execute_telescope_action = hbac_telescope_utils.execute_telescope_action
local refresh_picker = hbac_telescope_utils.refresh_picker
local json_encode_pin_storage = hbac_storage_utils.json_encode_pin_storage

local action_state = require("telescope.actions.state")
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local entry_display = require("telescope.pickers.entry_display")
local previewers = require("telescope.previewers")
local sorters = require("telescope.sorters")

local M = {}

local function display(pin)
	local function get_display_text()
		local display_path = hbac_telescope_utils.format_filepath(pin.abs_path)
		if display_path == "" then
			return pin.filename
		end
		return pin.filename .. " (" .. display_path .. ")"
	end

	local displayer = entry_display.create({
		separator = " ",
		items = {
			{ width = 2 },
			{ remaining = true },
		},
	})

	local icon, hl_group = hbac_telescope_utils.get_devicon(pin.abs_path)

	-- BUG: hl_group is returning correctly but not highlighting for this picker
	return displayer({
		{ icon, hl_group },
		get_display_text(),
	})
end

local function get_entries(keyname)
	local entries = {}
	local pin_storage = hbac_storage_utils.get_pin_storage() or {}
	if not hbac_storage_utils.general_storage_checks(pin_storage, keyname) then
		return
	end
	local storage_entry = pin_storage[keyname]
	local stored_pins = storage_entry.stored_pins
	for _, pin in pairs(stored_pins) do
		table.insert(entries, {
			filename = pin.abs_path,
			display = display(pin),
			value = pin,
			ordinal = pin.abs_path,
		})
	end
	return entries
end

local function make_finder(keyname)
	return finders.new_table({
		results = get_entries(keyname),
		entry_maker = function(entry)
			return {
				filename = entry.filename,
				value = entry.value,
				display = entry.display,
				ordinal = entry.ordinal,
			}
		end,
	})
end

M.preview_pin_storage_entry = function(keyname)
	local function hbac_recall_storage_picker()
		require("hbac.telescope.storage_picker").storage_picker()
	end

	local hbac_remove_file_from_entry = function(prompt_bufnr)
		local picker = action_state.get_current_picker(prompt_bufnr)
		local pin_storage = hbac_storage_utils.get_pin_storage() or {}
		local pin_storage_entry = pin_storage[keyname]
		local stored_pins = pin_storage_entry.stored_pins
		local function remove_item_from_stored_pins(index)
			table.remove(stored_pins, index)
		end
		execute_telescope_action(picker, remove_item_from_stored_pins, "index")
		json_encode_pin_storage(pin_storage)
		refresh_picker(picker, make_finder, keyname)
	end

	pickers
		.new({}, {
			prompt_title = "Hbac Stored Pins Preview",
			finder = make_finder(keyname),
			sorter = sorters.get_generic_fuzzy_sorter(),
			previewer = previewers.vim_buffer_cat.new({}),
			attach_mappings = function(_, map)
				map("i", "<Esc>", hbac_recall_storage_picker)
				map("i", "<M-x>", hbac_remove_file_from_entry)
				return true
			end,
		})
		:find()
end

return M
