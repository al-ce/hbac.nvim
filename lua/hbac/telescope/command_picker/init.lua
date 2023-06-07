local check_dependencies = require("hbac.telescope.telescope_utils").check_dependencies
if not check_dependencies() then
	return false
end

local hbac_storage = require("hbac.storage")
local hbac_storage_entry_previewer = require("hbac.telescope.storage_picker.storage_entry_previewer")
local action_state = require("telescope.actions.state")
local telescope_conf = require("telescope.config").values
local pickers = require("telescope.pickers")

local M = {}

local hbac_recall_storage_picker = hbac_storage_entry_previewer.hbac_recall_storage_picker

local function hbac_exec_command_on_pins()
	local command = action_state.get_selected_entry()
	local open_pin_storage_entry = hbac_storage.exec_command_on_storage_entry
	open_pin_storage_entry(M.storage_entry_keyname, command.value)
end

M.exec_command_on_pins = function(storage_entry_keyname)
	M.opts = M.opts or {}
	M.storage_entry_keyname = storage_entry_keyname
	local opts = M.opts

	local finder = require("hbac.telescope.command_picker.make_finder")
	pickers
		.new(opts, {
			prompt_title = "Hbac: Exec Command On Pins",
			results_title = "Commands",
			layout_strategy = "horizontal",
			layout_config = {
				height = 0.2,
				width = 0.2,
			},
			borderchars = {
				{ "─", "│", "─", "│", "┌", "┐", "┘", "└" },
				preview = { "─", "│", "─", "│", "┌", "┐", "┘", "└" },
			},
			finder = finder.make_finder(opts),
			sorter = telescope_conf.generic_sorter(opts),
			attach_mappings = function(_, map)
				map("i", "<Esc>", hbac_recall_storage_picker)
				map({ "n", "i" }, "<CR>", hbac_exec_command_on_pins)
				return true
			end,
		})
		:find()
end

return M
