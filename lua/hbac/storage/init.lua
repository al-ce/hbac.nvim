local hbac_config = require("hbac.setup").opts
local hbac_storage_utils = require("hbac.storage.utils")
local hbac_notify = require("hbac.utils").hbac_notify

local Path = require("plenary.path")
local data_dir = vim.fn.stdpath("data")
local pin_storage_file_path = Path:new(data_dir, "pin_storage.json")

local M = {}

M.get_pin_storage = function()
	if not pin_storage_file_path:exists() then
		return {}
	end
	local content = pin_storage_file_path:read()
	return vim.fn.json_decode(content)
end

M.store_pinned_bufs = function(keyname)
	local pinned_bufnrs = hbac_storage_utils.get_pinned_bufnrs()
	if not pinned_bufnrs then
		return nil
	end
	local pinned_bufs_data = hbac_storage_utils.make_pinned_bufs_data(pinned_bufnrs)
	local pin_storage = M.get_pin_storage() or {}
	local storage_entry
	local is_update = keyname ~= nil and pin_storage[keyname]
	keyname, storage_entry = hbac_storage_utils.create_storage_entry(pinned_bufs_data, keyname)
	if not keyname then
		return
	end
	local overwrite = hbac_storage_utils.confirm_duplicate_entry_overwrite(pin_storage, keyname, is_update)
	if overwrite == false then
		return
	end
	is_update = overwrite ~= nil and true
	pin_storage[keyname] = storage_entry
	pin_storage_file_path:write(vim.fn.json_encode(pin_storage), "w")

	hbac_storage_utils.storage_notification(keyname, is_update)
end

M.delete_pin_storage_entry = function(keyname)
	local pin_storage = M.get_pin_storage() or {}
	local storage_deletion_checks = hbac_storage_utils.deletion_checks(pin_storage, keyname)
	if not storage_deletion_checks then
		return
	end
	pin_storage[keyname] = nil
	pin_storage_file_path:write(vim.fn.json_encode(pin_storage), "w")
	hbac_notify("Pin storage: '" .. keyname .. "' deleted", "warn")
end

M.open_pin_storage_entry = function(keyname)
	local pin_storage = M.get_pin_storage() or {}
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
	local pin_storage = M.get_pin_storage() or {}
	local new_keyname = hbac_storage_utils.rename_checks(pin_storage, keyname)
	if not new_keyname then
		return
	end
	pin_storage[new_keyname] = pin_storage[keyname]
	pin_storage[keyname] = nil
	pin_storage_file_path:write(vim.fn.json_encode(pin_storage), "w")
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
	pin_storage_file_path:write(vim.fn.json_encode({}), "w")
	hbac_notify("Pin storage cleared", "warn")
end

return M
