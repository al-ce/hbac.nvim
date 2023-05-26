local hbac_config = require("hbac.setup").opts
local state = require("hbac.state")
local utils = require("hbac.utils")

local entry_display = require("telescope.pickers.entry_display")

local M = {}

M.display = function(entry)
	local bufnr, bufname = entry.value, entry.ordinal

	local function get_pin_icon()
		local pin_icons = hbac_config.telescope.pin_icons
		local is_pinned = state.is_pinned(bufnr)
		local pin_icon = is_pinned and pin_icons.pinned[1] or pin_icons.unpinned[1]
		local pin_icon_hl = is_pinned and pin_icons.pinned.hl or pin_icons.unpinned.hl
		return pin_icon, pin_icon_hl
	end

	local function get_display_text()
		local bufpath = utils.format_filepath(bufname)
		local display_filename = vim.fn.fnamemodify(bufname, ":t")
		if bufpath == "" then
			return display_filename
		end
		return display_filename .. " (" .. bufpath .. ")"
	end

	local displayer = entry_display.create({
		separator = " ",
		items = {
			{ width = 2 },
			{ width = 2 },
			{ remaining = true },
		},
	})

	return displayer({
		{ get_pin_icon() },
		{ utils.get_devicon(bufname) },
		get_display_text(),
	})
end

return M
