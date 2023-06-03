local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local hbac_config = require("hbac.setup").opts
local hbac_storage_entry_previewer = require("hbac.telescope.storage_picker.storage_entry_previewer")
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

local function hbac_rename_stored_pins(prompt_bufnr)
	local rename_stored_pins = pin_storage.rename_pin_storage_entry
	storage_picker_action(prompt_bufnr, rename_stored_pins)
end

local function hbac_clear_pin_storage(prompt_bufnr)
	local clear_pin_storage = pin_storage.clear_pin_storage
	storage_picker_action(prompt_bufnr, clear_pin_storage)
end

local hbac_preview_stored_pins = function(prompt_bufnr)
	local preview_stored_pins = hbac_storage_entry_previewer.preview_pin_storage_entry
	local picker = action_state.get_current_picker(prompt_bufnr)
	execute_telescope_action(picker, preview_stored_pins)
end

local hbac_update_stored_pins = function(prompt_bufnr)
	local update_stored_pins = pin_storage.store_pinned_bufs
	storage_picker_action(prompt_bufnr, update_stored_pins)
end

local hbac_add_cur_buf_to_entry = function(prompt_bufnr)
	local picker = action_state.get_current_picker(prompt_bufnr)
	local make_finder = require("hbac.telescope.storage_picker.make_finder")
	local finder_opts = make_finder.finder_opts
	execute_telescope_action(picker, pin_storage.add_cur_buf_to_entry)
	hbac_telescope_utils.refresh_picker(picker, make_finder.make_finder, finder_opts)
end

M.attach_mappings = function(_, map)
	local hbac_storage_picker_actions = {
		open_stored_pins = hbac_open_stored_pins,
		delete_stored_pins = hbac_delete_stored_pins,
		rename_stored_pins = hbac_rename_stored_pins,
		clear_pin_storage = hbac_clear_pin_storage,
		preview_stored_pins = hbac_preview_stored_pins,
		update_stored_pins = hbac_update_stored_pins,
		add_cur_buf_to_entry = hbac_add_cur_buf_to_entry,
	}

	for mode, hbac_cmds in pairs(hbac_config.telescope.storage_picker.mappings) do
		for hbac_cmd, key in pairs(hbac_cmds) do
			map(mode, key, hbac_storage_picker_actions[hbac_cmd])
		end
	end

	return true
end

return M
