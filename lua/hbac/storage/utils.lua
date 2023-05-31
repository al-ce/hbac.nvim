local hbac_config = require("hbac.setup").opts
local hbac_notify = require("hbac.utils").hbac_notify
local state = require("hbac.state")
local hbac_utils = require("hbac.utils")
local hbac_telescope_utils = require("hbac.telescope.telescope_utils")

local M = {}

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

M.make_pinned_bufs_data = function(pinned_bufnrs)
	local pinned_bufs_data = {}
	for _, bufnr in ipairs(pinned_bufnrs) do
		local bufname = vim.fn.bufname(bufnr)
		local filepath = hbac_telescope_utils.format_filepath(bufname)
		local filename = vim.fn.fnamemodify(bufname, ":t")
		local abs_path = vim.fn.fnamemodify(bufname, ":p")
		table.insert(pinned_bufs_data, {
			abs_path = abs_path,
			filename = filename,
			filepath = filepath,
		})
	end
	return pinned_bufs_data
end

M.create_storage_entry = function(pinned_bufs_data)
	local cwd = vim.fn.getcwd() or vim.fn.expand("%:p:h")
	local keyname = vim.fn.input("Hbac Pin Storage\nEntry name (or %t for timestamp): ")
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

M.confirm_duplicate_entry_overwrite = function(pin_storage, keyname)
	if not pin_storage[keyname] then
		return true
	end
	local msg = "Hbac Pin Storage\nOverwrite existing entry '%s'? (y/n): "
	local overwrite = vim.fn.input(string.format(msg, keyname))
	if overwrite == "y" then
		return true
	end
	hbac_notify("Pin storage cancelled", "warn")
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

M.deletion_checks = function(pin_storage, keyname)
	-- TODO: don't check for EVERY entry during multiselect Telescope deletion action, just confirm once
	M.general_storage_checks(pin_storage, keyname)
	local msg = "Hbac Pin Storage\nRemove entry '%s'? (y/n): "
	local remove = vim.fn.input(string.format(msg, keyname))
	if remove ~= "y" then
		hbac_notify("Pin storage cancelled", "warn")
		return
	end
	return true
end

M.rename_checks = function(pin_storage, keyname)
	M.general_storage_checks(pin_storage, keyname)
	local msg = "Hbac Pin Storage\nRename entry '%s' to: "
	local new_keyname = vim.fn.input(string.format(msg, keyname))
	if new_keyname == "" then
		hbac_notify("Pin storage: new name cannot be empty\n'" .. keyname .. "' not renamed", "warn")
		return
	end
	local overwrite = M.confirm_duplicate_entry_overwrite(pin_storage, new_keyname)
	if not overwrite then
		hbac_notify("Pin storage: '" .. keyname .. "' not renamed", "warn")
		return
	end
	return new_keyname
end

M.storage_notification = function(keyname)
	local notify_state = hbac_config.notify
	hbac_utils.set_notify(true)
	hbac_notify("Pin storage: '" .. keyname .. "' stored")
	hbac_utils.set_notify(notify_state)
end

return M
