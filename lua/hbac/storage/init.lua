local check_dependencies = require("hbac.telescope.telescope_utils").check_dependencies
if not check_dependencies() then
	return false
end

local state = require("hbac.state")
local hbac_config = require("hbac.setup").opts
local hbac_utils = require("hbac.utils")
local hbac_telescope_utils = require("hbac.telescope.telescope_utils")
local hbac_notify = require("hbac.utils").hbac_notify

local cwd = vim.fn.getcwd() or vim.fn.expand("%:p:h")
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

local function get_pinned_bufnrs()
	return vim.tbl_filter(function(bufnr)
		return state.pinned_buffers[bufnr]
	end, hbac_utils.get_listed_buffers())
end

local function make_pinned_bufs_data(pinned_bufnrs)
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

local function create_storage_entry(pinned_bufs_data)
	local keyname = vim.fn.input("Hbac Pin Storage\nEntry name (leave blank to use timestamp): ")
	local timestamp = os.date("%Y-%m-%d %H:%M:%S")
	keyname = keyname == "" and tostring(timestamp) or keyname
	local proj_root = cwd:gsub(vim.env.HOME, "~")
	return keyname, {
		proj_root = proj_root,
		stored_pins = pinned_bufs_data,
		timestamp = timestamp,
	}
end

local function confirm_duplicate_overwrite(pin_storage, keyname)
	if not pin_storage[keyname] then
		return true
	end
	local msg = "Hbac Pin Storage\nEntry with name '%s' already exists. Overwrite? (y/n): "
	local overwrite = vim.fn.input(string.format(msg, keyname))
	if overwrite == "y" then
		return true
	end
	hbac_notify("Pin storage cancelled", "warn")
end

M.store_pinned_bufs = function()
	local pinned_bufnrs = get_pinned_bufnrs()
	if #pinned_bufnrs == 0 then
		hbac_notify("No pins to store", "warn")
		return nil
	end
	local pinned_bufs_data = make_pinned_bufs_data(pinned_bufnrs)
	local pin_storage = M.get_pin_storage()
	local keyname, storage_entry = create_storage_entry(pinned_bufs_data)
	if not confirm_duplicate_overwrite(pin_storage, keyname) then
		return
	end
	pin_storage[keyname] = storage_entry
	pin_storage_file_path:write(vim.fn.json_encode(pin_storage), "w")

	-- ensure notification is shown
	local notify_state = hbac_config.notify
	hbac_utils.set_notify(true)
	hbac_notify("Pin storage: '" .. keyname .. "' stored")
	hbac_utils.set_notify(notify_state)
end

M.delete_pin_storage_entry = function(keyname)
	local pin_storage = M.get_pin_storage() or {}
	local keynames = vim.tbl_keys(pin_storage)
	if #keynames == 0 then
		hbac_notify("No pin storage entries to remove", "warn")
		return
	end
	if not pin_storage[keyname] then
		hbac_notify("No pin storage entry with that name", "warn")
		return
	end

	local msg = "Hbac Pin Storage\nRemove entry '%s'? (y/n): "
	local remove = vim.fn.input(string.format(msg, keyname))
	if remove ~= "y" then
		hbac_notify("Pin storage cancelled", "warn")
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
