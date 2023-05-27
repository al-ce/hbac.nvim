local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local pin_storage = require("hbac.storage")
local hbac_telescope_utils = require("hbac.telescope.telescope_utils")
local execute_telescope_action = hbac_telescope_utils.execute_telescope_action

local M = {}

local function storage_picker_action(prompt_bufnr, action)
	local picker = action_state.get_current_picker(prompt_bufnr)
	actions.close(prompt_bufnr)
	execute_telescope_action(picker, action)
end

M.hbac_open_stored_pins = function(prompt_bufnr)
	local open_stored_pins = pin_storage.open_pin_storage_entry
	storage_picker_action(prompt_bufnr, open_stored_pins)
end

return M
