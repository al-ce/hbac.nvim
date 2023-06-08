local hbac_config = require("hbac.setup").opts
local hbac_storage_utils = require("hbac.storage.utils")
local hbac_utils = require("hbac.utils")
local hbac_notify = require("hbac.utils").hbac_notify
local json_encode_pin_storage = hbac_storage_utils.json_encode_pin_storage
local get_pin_storage = hbac_storage_utils.get_pin_storage

local M = {}

M.store_pinned_bufs = function(keyname)
	local pinned_bufnrs = hbac_storage_utils.get_pinned_bufnrs()
	if not pinned_bufnrs then
		return nil
	end
	local pinned_bufs_data = hbac_storage_utils.get_data_of_pinned_bufs(pinned_bufnrs)
	local pin_storage = get_pin_storage() or {}
	local storage_entry
	local is_update = keyname ~= nil and pin_storage[keyname]
	keyname, storage_entry = hbac_storage_utils.create_storage_entry(pinned_bufs_data, keyname)
	if not keyname then
		return
	end
	local overwrite = hbac_storage_utils.confirm_duplicate_entry_overwrite(pin_storage, keyname, is_update)
	if overwrite == false then
		hbac_notify("Pin storage cancelled")
		return
	end
	is_update = overwrite ~= nil and true
	pin_storage[keyname] = storage_entry
	json_encode_pin_storage(pin_storage)
	hbac_storage_utils.storage_notification(keyname, is_update)
end

M.delete_pin_storage_entry = function(keyname)
	local pin_storage = get_pin_storage() or {}
	local storage_deletion_checks = hbac_storage_utils.entry_deletion_checks(pin_storage, keyname)
	if not storage_deletion_checks then
		return
	end
	pin_storage[keyname] = nil
	json_encode_pin_storage(pin_storage)
	hbac_notify("Pin storage: '" .. keyname .. "' deleted", "warn")
end

M.exec_command_on_storage_entry = function(keyname, command)
	local pin_storage = get_pin_storage() or {}
	if not hbac_storage_utils.general_storage_checks(pin_storage, keyname) then
		return
	end
	command = command or "open"
	local command_config = hbac_config.storage[command]
	if command_config == nil then
		hbac_notify("Pin storage: command '" .. command .. "' not found", "warn")
		return
	end
	local prehook = command_config.prehook
	if prehook then
		prehook(keyname)
	end
	if command_config.command then
		local storage_entry = pin_storage[keyname]
		local stored_pins = storage_entry.stored_pins
		for _, pin in pairs(stored_pins) do
			command_config.command(pin)
		end
	end
	local posthook = command_config.posthook
	if posthook then
		posthook(keyname)
	end
	local timestamp = os.date("%Y-%m-%d %H:%M:%S")
	pin_storage[keyname].timestamp = timestamp
	json_encode_pin_storage(pin_storage)
	hbac_notify("Pin storage: ran command '" .. command .. "' on '" .. keyname .. "'")
end

M.rename_pin_storage_entry = function(keyname)
	local pin_storage = get_pin_storage() or {}
	local new_keyname = hbac_storage_utils.entry_rename_checks(pin_storage, keyname)
	if not new_keyname then
		return
	end
	pin_storage[new_keyname] = pin_storage[keyname]
	pin_storage[new_keyname].timestamp = os.date("%Y-%m-%d %H:%M:%S")
	pin_storage[keyname] = nil
	json_encode_pin_storage(pin_storage)
	hbac_notify("Pin storage: '" .. keyname .. "' renamed to '" .. new_keyname .. "'")
end

M.clear_pin_storage = function()
	local msg = [[--Hbac Pin Storage--
WARNING! This will clear all pin storage entries.
Type 'DELETE' to confirm or anything else to cancel: ]]
	local user_input = vim.fn.input(msg)
	if user_input ~= "DELETE" then
		hbac_notify("Pin storage clear cancelled", "warn")
		return
	end
	json_encode_pin_storage({})
	hbac_notify("Pin storage cleared", "warn")
end

local function add_or_remove_file_in_entry(keyname, add_or_remove, bufnr)
	local add, remove = add_or_remove == "add", add_or_remove == "remove"
	local pin_storage = get_pin_storage() or {}
	local pin_storage_entry = pin_storage[keyname]
	if not hbac_storage_utils.general_storage_checks(pin_storage, keyname) then
		return
	end
	local cur_pinned_buf_data = hbac_storage_utils.get_single_pinned_buf_data(bufnr)
	if not cur_pinned_buf_data then
		hbac_notify("Pin storage: No file found for current buffer", "warn")
		return
	end
	local stored_pins = pin_storage_entry.stored_pins
	local index = hbac_storage_utils.file_is_in_stored_pins(stored_pins, cur_pinned_buf_data)
	local warn_msg = (
		"Pin storage: '"
		.. keyname
		.. ((add and "' already contains ") or (remove and "' does not contain "))
		.. "this file:\n\n"
		.. cur_pinned_buf_data.abs_path
	)
	if (add and index) or (remove and not index) then
		hbac_notify(warn_msg, "warn")
		return
	end
	if add then
		table.insert(stored_pins, cur_pinned_buf_data)
	elseif remove then
		table.remove(stored_pins, index)
	end
	local timestamp = os.date("%Y-%m-%d %H:%M:%S")
	pin_storage_entry.timestamp = timestamp
	json_encode_pin_storage(pin_storage)
	local to_or_from = (add and "added to" or (remove and "removed from"))
	hbac_notify("Pin storage: " .. cur_pinned_buf_data.filename .. " " .. to_or_from .. " '" .. keyname .. "'")
end

M.add_buf_to_entry = function(keyname, bufnr)
	if not bufnr then
		local bufnrs = hbac_utils.get_listed_buffers()
		bufnr = hbac_utils.most_recent_buf(bufnrs)
	end
	add_or_remove_file_in_entry(keyname, "add", bufnr)
end

M.remove_buf_from_entry = function(keyname, bufnr)
	add_or_remove_file_in_entry(keyname, "remove", bufnr)
end

return M
