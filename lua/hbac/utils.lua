local Path = require("plenary.path")
local cwd = vim.loop.cwd()
local os_home = vim.loop.os_homedir()
local state = require("hbac.state")

local M = {}

M.buf_autoclosable = function(bufnr)
	local current_buf = vim.api.nvim_get_current_buf()
	if state.is_pinned(bufnr) or bufnr == current_buf then
		return false
	end
	local buffer_windows = vim.fn.win_findbuf(bufnr)
	local config = require("hbac.setup").opts
	if #buffer_windows > 0 and not config.close_buffers_with_windows then
		return false
	end
	return true
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

M.get_listed_buffers = function()
	return vim.tbl_filter(function(bufnr)
		return vim.api.nvim_buf_get_option(bufnr, "buflisted")
	end, vim.api.nvim_list_bufs())
end

return M
