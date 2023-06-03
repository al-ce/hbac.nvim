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

M.open_pin_storage_entry = function(keyname)
	local pin_storage = get_pin_storage() or {}
	if not hbac_storage_utils.general_storage_checks(pin_storage, keyname) then
		return
	end
	hbac_config.storage.open.prehook()
	local entry = pin_storage[keyname]
	local stored_pins = entry.stored_pins
	for _, pin in pairs(stored_pins) do
		hbac_config.storage.open.on_open(pin)
	end
	hbac_config.storage.open.posthook()
	hbac_notify("Pin storage: '" .. keyname .. "' opened")
end

M.rename_pin_storage_entry = function(keyname)
	local pin_storage = get_pin_storage() or {}
	local new_keyname = hbac_storage_utils.entry_rename_checks(pin_storage, keyname)
	if not new_keyname then
		return
	end
	pin_storage[new_keyname] = pin_storage[keyname]
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

local function add_or_remove_file_in_entry(keyname, add_or_remove)
	local add, remove = add_or_remove == "add", add_or_remove == "remove"
  local bufnrs = hbac_utils.get_listed_buffers()
	local most_recent_buf = hbac_utils.most_recent_buf(bufnrs)
	local pin_storage = get_pin_storage() or {}
	local pin_storage_entry = pin_storage[keyname]
	if not hbac_storage_utils.general_storage_checks(pin_storage, keyname) then
		return
	end
	local cur_pinned_buf_data = hbac_storage_utils.get_single_pinned_buf_data(most_recent_buf)
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
	json_encode_pin_storage(pin_storage)
	local to_or_from = (add and "added to" or (remove and "removed from"))
	hbac_notify("Pin storage: " .. cur_pinned_buf_data.filename .. " " .. to_or_from .. " '" .. keyname .. "'")
end

M.add_cur_buf_to_entry = function(keyname)
	add_or_remove_file_in_entry(keyname, "add")
end

M.remove_cur_buf_from_entry = function(keyname)
	add_or_remove_file_in_entry(keyname, "remove")
end

return M
