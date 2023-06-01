local hbac_config = require("hbac.setup").opts
local state = require("hbac.state")
local subcommands = require("hbac.command.subcommands")
local hbac_telescope_utils = require("hbac.telescope.telescope_utils")
local hbac_utils = require("hbac.utils")
local make_finder = require("hbac.telescope.pin_picker.make_finder")

local action_state = require("telescope.actions.state")

local M = {}

local function pin_picker_action(prompt_bufnr, action)
	local notify = hbac_config.notify
	hbac_utils.set_notify(false)
	local picker = action_state.get_current_picker(prompt_bufnr)
	hbac_telescope_utils.execute_telescope_action(picker, action)
	hbac_telescope_utils.refresh_picker(picker, make_finder.make_finder)
	hbac_utils.set_notify(notify)
end

local function hbac_toggle_selections(prompt_bufnr)
	pin_picker_action(prompt_bufnr, state.toggle_pin)
end
local function hbac_pin_all(prompt_bufnr)
	pin_picker_action(prompt_bufnr, subcommands.pin_all)
end
local function hbac_unpin_all(prompt_bufnr)
	pin_picker_action(prompt_bufnr, subcommands.unpin_all)
end
local function hbac_close_unpinned(prompt_bufnr)
	pin_picker_action(prompt_bufnr, subcommands.close_unpinned)
end
local function hbac_delete_buffer(prompt_bufnr)
	pin_picker_action(prompt_bufnr, hbac_config.close_command)
end
local function hbac_store_pinned_bufs(prompt_bufnr)
	local picker = action_state.get_current_picker(prompt_bufnr)
  local store_pinned_bufs = subcommands.store_pinned_bufs
	hbac_telescope_utils.execute_telescope_action(picker, store_pinned_bufs)
	hbac_telescope_utils.refresh_picker(picker, make_finder.make_finder)
end

M.attach_mappings = function(_, map)
	local hbac_telescope_actions = {
		close_unpinned = hbac_close_unpinned,
		delete_buffer = hbac_delete_buffer,
		pin_all = hbac_pin_all,
		unpin_all = hbac_unpin_all,
		toggle_selections = hbac_toggle_selections,
		store_pinned_bufs = hbac_store_pinned_bufs,
	}

	for mode, hbac_cmds in pairs(hbac_config.telescope.pin_picker.mappings) do
		for hbac_cmd, key in pairs(hbac_cmds) do
			map(mode, key, hbac_telescope_actions[hbac_cmd])
		end
	end

	return true
end

return M
