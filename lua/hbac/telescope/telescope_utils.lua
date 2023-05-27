local action_state = require("telescope.actions.state")
local Path = require("plenary.path")
local cwd = vim.loop.cwd()
local os_home = vim.loop.os_homedir()

local hbac_config = require("hbac.setup").opts
local utils = require("hbac.utils")
local make_finder = require("hbac.telescope.make_finder").make_finder

local M = {}

M.refresh_picker = function(picker)
	local row = picker:get_selection_row()
	picker:register_completion_callback(function()
		picker:set_selection(row)
	end)
	picker:refresh(make_finder(), { reset_prompt = false })
end

M.execute_telescope_action = function(picker, action)
	local multi_selection = picker:get_multi_selection()
	local notify = hbac_config.notify
	utils.set_notify(false)
	if next(multi_selection) then
		for _, entry in ipairs(multi_selection) do
			action(entry.value)
		end
	else
		local single_selection = action_state.get_selected_entry()
		action(single_selection.value)
	end
	utils.set_notify(notify)
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

M.get_devicon = function(bufname)
	local has_devicons, devicons = pcall(require, "nvim-web-devicons")
	if not has_devicons then
		return "", ""
	end
	return devicons.get_icon(bufname, string.match(bufname, "%a+$"), { default = true })
end

return M
