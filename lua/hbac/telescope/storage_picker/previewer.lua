local hbac_utils = require("hbac.utils")
local hbac_telescope_utils = require("hbac.telescope.telescope_utils")

local previewers = require("telescope.previewers")

local M = {}

local preview_fn = function(self, entry, status)
	local ns = vim.api.nvim_create_namespace("telescope_previewer_pin_storage")
	local highlight_line = function(hlgroup, line, col_start, col_end)
		vim.api.nvim_buf_add_highlight(self.state.bufnr, ns, hlgroup, line, col_start, col_end)
	end

	vim.api.nvim_buf_clear_namespace(self.state.bufnr, ns, 0, -1)
	vim.api.nvim_win_set_buf(status.preview_win, self.state.bufnr)
	local stored_pins = entry.stored_pins
	local lines = {}

	local timestamp = entry.timestamp
	table.insert(lines, timestamp)

	local listed_bufs_pinned_states = hbac_utils.get_listed_bufs_pinned_states()
	local pin_icons = {}
	local devicon_hls = {}
	for _, pin in pairs(stored_pins) do
		local abs_path = pin.abs_path
		local pin_icon, hl = hbac_telescope_utils.get_pinned_state_icon(abs_path, listed_bufs_pinned_states)
		if pin_icon == " " then
			pin_icon = "  "
		end
		table.insert(pin_icons, { pin_icon, hl = hl })
		local devicon, devicon_hl = hbac_telescope_utils.get_devicon(abs_path)
		table.insert(devicon_hls, devicon_hl)
		local display_filename = hbac_telescope_utils.get_display_text(abs_path)
		local display = pin_icon .. " " .. devicon .. " " .. display_filename
		table.insert(lines, display)
	end
	vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)

	highlight_line("TelescopeResultsNumber", 0, 0, 10) -- Highilights date
	highlight_line("TelescopeResultsIdentifier", 0, 11, -1) -- Highlights time
	for i, pin_icon in ipairs(pin_icons) do
		local pin_hl, devicon_hl = pin_icon.hl, devicon_hls[i]
		local pin_icon_col_end = #pin_icon[1]
		local dev_icon_col_start = pin_icon_col_end + 2
		highlight_line(pin_hl, i, 0, pin_icon_col_end) -- Highlights pin icons
		highlight_line(devicon_hl, i, dev_icon_col_start, dev_icon_col_start + 2) -- Highlights devicons
	end
end

M.previewer = function()
	return previewers.new({
		setup = function()
			return {
				bufnr = vim.api.nvim_create_buf(false, true),
			}
		end,
		preview_fn = function(self, entry, status)
			preview_fn(self, entry, status)
		end,
		teardown = function(self)
			if self.state == nil then
				return
			end
			vim.api.nvim_buf_delete(self.state.bufnr, { force = true })
			self.state.bufnr = nil
		end,
	})
end

return M
