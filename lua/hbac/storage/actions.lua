local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local pin_storage = require("hbac.storage")

local M = {}

M.hbac_open_stored_pins = function(prompt_bufnr)
	local open_stored_pins = pin_storage.open_pin_storage_entry

	local picker = action_state.get_current_picker(prompt_bufnr)
	local multi_selection = picker:get_multi_selection()

	actions.close(prompt_bufnr)
	if next(multi_selection) then
		for _, entry in ipairs(multi_selection) do
			local entry_key = entry.value
			open_stored_pins(entry_key)
		end
	else
		local single_selection = action_state.get_selected_entry()
		local entry_key = single_selection.ordinal
		open_stored_pins(entry_key)
	end
end

return M
