local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local hbac_config = require("hbac.setup").opts
local pin_storage = require("hbac.storage")
local hbac_telescope_utils = require("hbac.telescope.telescope_utils")
local execute_telescope_action = hbac_telescope_utils.execute_telescope_action

local M = {}

local function storage_picker_action(prompt_bufnr, action)
	local picker = action_state.get_current_picker(prompt_bufnr)
	actions.close(prompt_bufnr)
	execute_telescope_action(picker, action)
end

local function hbac_open_stored_pins(prompt_bufnr)
	local open_stored_pins = pin_storage.open_pin_storage_entry
	storage_picker_action(prompt_bufnr, open_stored_pins)
end

local function hbac_delete_stored_pins(prompt_bufnr)
	local delete_stored_pins = pin_storage.delete_pin_storage_entry
	storage_picker_action(prompt_bufnr, delete_stored_pins)
end

M.attach_mappings = function(_, map)
	local hbac_storage_picker_actions = {
		open_stored_pins = hbac_open_stored_pins,
		delete_stored_pins = hbac_delete_stored_pins,
	}

	for mode, hbac_cmds in pairs(hbac_config.telescope.storage_picker.mappings) do
		for hbac_cmd, key in pairs(hbac_cmds) do
			map(mode, key, hbac_storage_picker_actions[hbac_cmd])
		end
	end

	return true
end

return M
