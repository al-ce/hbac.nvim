local check_dependencies = require("hbac.telescope.telescope_utils").check_dependencies
if not check_dependencies() then
	return false
end

local state = require("hbac.state")
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

M.store_pinned_bufs = function()
	local pinned_bufnrs = hbac_storage_utils.get_pinned_bufnrs()
	if #pinned_bufnrs == 0 then
		hbac_notify("No pins to store", "warn")
		return nil
	end
	local pinned_bufs_data = hbac_storage_utils.make_pinned_bufs_data(pinned_bufnrs)
	local pin_storage = M.get_pin_storage()
	local keyname, storage_entry = hbac_storage_utils.create_storage_entry(pinned_bufs_data)
	local overwrite = hbac_storage_utils.confirm_duplicate_entry_overwrite(pin_storage, keyname)
	if not overwrite then
		return
	end
	pin_storage[keyname] = storage_entry
	pin_storage_file_path:write(vim.fn.json_encode(pin_storage), "w")

	hbac_storage_utils.storage_notification(keyname)
end

M.delete_pin_storage_entry = function(keyname)
	local pin_storage = M.get_pin_storage() or {}

	local storage_deletion_checks = hbac_storage_utils.deletion_checks(pin_storage, keyname)
	if not storage_deletion_checks then
		return
	end

	pin_storage[keyname] = nil
	pin_storage_file_path:write(vim.fn.json_encode(pin_storage), "w")
	hbac_notify("Pin storage: '" .. keyname .. "' removed", "warn")
end

M.open_pin_storage_entry = function(keyname)
	local pin_storage = M.get_pin_storage() or {}
	if not pin_storage[keyname] then
		hbac_notify("No pin storage entry with that name", "warn")
		return
	end
	hbac_config.storage.open.prehook()
	local entry = pin_storage[keyname]
	local stored_pins = entry.stored_pins
	for _, pin in pairs(stored_pins) do
		vim.cmd("silent! e " .. pin.abs_path)
		local bufnr = vim.fn.bufnr()
		state.pinned_buffers[bufnr] = true
	end
	hbac_config.storage.open.posthook()
	hbac_notify("Pin storage: '" .. keyname .. "' opened")
end

return M
