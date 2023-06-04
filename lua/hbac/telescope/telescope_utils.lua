local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local Path = require("plenary.path")
local cwd = vim.loop.cwd()
local os_home = vim.loop.os_homedir()

local hbac_notify = require("hbac.utils").hbac_notify

local M = {}

M.check_dependencies = function()
	local missing = ""
	for _, dependency in ipairs({ "plenary", "telescope" }) do
		if not pcall(require, dependency) then
			missing = missing .. "\n- " .. dependency .. ".nvim"
		end
	end

	if missing ~= "" then
		local msg = "Missing dependencies:" .. missing
		hbac_notify(msg, "error")
		return false
	end
	return true
end

M.refresh_picker = function(picker, make_finder, finder_opts)
	local row = picker:get_selection_row()
	local num_results = picker.manager:num_results()
	picker:register_completion_callback(function()
		if row == num_results - 1 then
			row = row - 1
			local prompt_bufnr = vim.api.nvim_get_current_buf() -- NOTE unsure if this is consistent
			actions.move_to_bottom(prompt_bufnr)
		else
			picker:set_selection(row)
		end
	end)
	picker:refresh(make_finder(finder_opts), { reset_prompt = false })
end

M.execute_telescope_action = function(picker, action, entry_field)
	entry_field = entry_field or "value"
	local multi_selection = picker:get_multi_selection()
	if next(multi_selection) then
		for _, entry in ipairs(multi_selection) do
			action(entry[entry_field])
		end
	else
		local single_selection = action_state.get_selected_entry()
		action(single_selection[entry_field])
	end
end

M.format_filepath = function(bufname)
	local path = vim.fn.fnamemodify(bufname, ":p:h")
	if cwd and vim.startswith(path, cwd) then
		path = string.sub(path, #cwd + 2)
	elseif os_home and vim.startswith(path, os_home) then
		path = "~/" .. Path:new(path):make_relative(os_home)
	end
	return path
end

M.get_display_text = function(filepath)
	local bufpath = M.format_filepath(filepath)
	local display_filename = vim.fn.fnamemodify(filepath, ":t")
	if bufpath == "" then
		return display_filename
	end
	return display_filename .. " (" .. bufpath .. ")"
end

M.get_pinned_state_icon = function(abs_path, listed_bufs_pinned_states)
	local hbac_utils = require("hbac.utils")
	local pinned_state = listed_bufs_pinned_states[abs_path]
	if pinned_state == nil then
		return " ", "Normal"
	end
	return hbac_utils.get_pin_icon(pinned_state.bufnr)
end

M.get_devicon = function(bufname)
	local has_devicons, devicons = pcall(require, "nvim-web-devicons")
	if not has_devicons then
		return " ", ""
	end
	return devicons.get_icon(bufname, string.match(bufname, "%a+$"), { default = true })
end

return M
