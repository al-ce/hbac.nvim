local hbac_config = require("hbac.setup").opts
local hbac_notify = require("hbac.utils").hbac_notify
local state = require("hbac.state")
local hbac_utils = require("hbac.utils")
local hbac_telescope_utils = require("hbac.telescope.telescope_utils")

local Path = require("plenary.path")
local data_dir = vim.fn.stdpath("data")
local pin_storage_file_path = Path:new(data_dir, "hbac_pin_storage.json")

local M = {}

M.get_pin_storage = function()
	if not pin_storage_file_path:exists() then
		return {}
	end
	local content = pin_storage_file_path:read()
	return vim.fn.json_decode(content)
end

M.json_encode_pin_storage = function(pin_storage)
	pin_storage_file_path:write(vim.fn.json_encode(pin_storage), "w")
end

M.file_is_in_stored_pins = function(stored_pins, cur_pinned_buf_data)
	for index, pinned_buf_data in ipairs(stored_pins) do
		local inspected_cur_buf_data = vim.inspect(cur_pinned_buf_data)
		local inspected_pinned_buf_data = vim.inspect(pinned_buf_data)
		if inspected_cur_buf_data == inspected_pinned_buf_data then
			return index
		end
	end
end

M.get_pinned_bufnrs = function()
	local pinned_buffnrs = vim.tbl_filter(function(bufnr)
		return state.pinned_buffers[bufnr]
	end, hbac_utils.get_listed_buffers())
	if #pinned_buffnrs == 0 then
		hbac_notify("No pins to store", "warn")
		return nil
	end
	return pinned_buffnrs
end

M.get_single_pinned_buf_data = function(bufnr)
	local bufname = vim.fn.bufname(bufnr)
	local abs_path = vim.fn.fnamemodify(bufname, ":p")
	local filename = vim.fn.fnamemodify(bufname, ":t")
	local filepath = hbac_telescope_utils.format_filepath(bufname)
	return {
		abs_path = abs_path,
		filename = filename,
		filepath = filepath,
	}
end

M.get_data_of_pinned_bufs = function(pinned_bufnrs)
	local pinned_bufs_data = {}
	for _, bufnr in ipairs(pinned_bufnrs) do
		local buf_data = M.get_single_pinned_buf_data(bufnr)
		table.insert(pinned_bufs_data, buf_data)
	end
	return pinned_bufs_data
end

M.create_storage_entry = function(pinned_bufs_data, keyname)
	local cwd = vim.fn.getcwd() or vim.fn.expand("%:p:h")
	keyname = keyname or vim.fn.input("Hbac Pin Storage\nNew entry name (or %t for timestamp): ")
	if keyname == "" then
		hbac_notify("Pin storage cancelled", "warn")
		return nil, nil
	end
	local timestamp = os.date("%Y-%m-%d %H:%M:%S")
	keyname = keyname == "%t" and tostring(timestamp) or keyname
	local proj_root = cwd:gsub(vim.env.HOME, "~")
	return keyname, {
		proj_root = proj_root,
		stored_pins = pinned_bufs_data,
		timestamp = timestamp,
	}
end

M.confirm_duplicate_entry_overwrite = function(pin_storage, keyname, is_update)
	if not pin_storage[keyname] then
		return
	end
	local write_type = is_update and "Update" or "Overwrite"
	local msg = "Hbac Pin Storage\n%s entry '%s'? (y/n): "
	local overwrite = vim.fn.input(string.format(msg, write_type, keyname))
	if overwrite == "y" then
		return true
	end
	return false
end

M.general_storage_checks = function(pin_storage, keyname)
	local keynames = vim.tbl_keys(pin_storage)
	if #keynames == 0 then
		hbac_notify("Pin storage: no stored pins", "warn")
		return
	end
	if not pin_storage[keyname] then
		hbac_notify("Pin storage: no entry with that name", "warn")
		return
	end
	return true
end

M.entry_deletion_checks = function(pin_storage, keyname)
	-- TODO: don't check for EVERY entry during multiselect Telescope deletion action, just confirm once
	M.general_storage_checks(pin_storage, keyname)
	local msg = "Hbac Pin Storage\nRemove entry '%s'? (y/n): "
	local remove = vim.fn.input(string.format(msg, keyname))
	if remove ~= "y" then
		hbac_notify("Pin deletion cancelled", "warn")
		return
	end
	return true
end

M.entry_rename_checks = function(pin_storage, keyname)
	M.general_storage_checks(pin_storage, keyname)
	local msg = "Hbac Pin Storage\nRename entry '%s' to: "
	local new_keyname = vim.fn.input(string.format(msg, keyname))
	if new_keyname == "" then
		hbac_notify("Pin storage: new name cannot be empty\n'" .. keyname .. "' not renamed", "warn")
		return
	end
	local overwrite = M.confirm_duplicate_entry_overwrite(pin_storage, new_keyname)
	if overwrite == false then
		hbac_notify("Pin storage: '" .. keyname .. "' not renamed", "warn")
		return
	end
	return new_keyname
end

M.storage_notification = function(keyname, is_update)
	local notify_state = hbac_config.notify
	hbac_utils.set_notify(true)
	hbac_notify("Pin storage: '" .. keyname .. "' " .. (is_update and "updated" or "created"))
	hbac_utils.set_notify(notify_state)
end

return M
