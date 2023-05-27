local hbac_telescope_utils = require("hbac.telescope.telescope_utils")

local previewers = require("telescope.previewers")

local M = {}

M.previewer = function()
	return previewers.new({
		setup = function()
			return {
				bufnr = vim.api.nvim_create_buf(false, true),
			}
		end,
		preview_fn = function(self, entry, status)
			local function get_file_display_text(bufname)
				local bufpath = hbac_telescope_utils.format_filepath(bufname)
				local display_filename = vim.fn.fnamemodify(bufname, ":t")
				if bufpath ~= "" and bufpath ~= "/" then
					return display_filename .. " (" .. bufpath .. ")"
				end
				return display_filename
			end

			local ns = vim.api.nvim_create_namespace("telescope_previewer_pin_storage")
			vim.api.nvim_buf_clear_namespace(self.state.bufnr, ns, 0, -1)
			vim.api.nvim_win_set_buf(status.preview_win, self.state.bufnr)
			local stored_pins = entry.stored_pins
			local lines = {}

			local timestamp = entry.timestamp
			table.insert(lines, timestamp)

			local devicon_hls = {}
			for _, pin in pairs(stored_pins) do
				local path = pin.filepath
				local filename = pin.filename
				local full_path = path .. "/" .. filename

				local devicon, hl = hbac_telescope_utils.get_devicon(full_path)
				table.insert(devicon_hls, hl)
				local display_filename = get_file_display_text(full_path)
				local display = devicon .. " " .. display_filename
				table.insert(lines, display)
			end
			vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)

			-- Highilights date
			vim.api.nvim_buf_add_highlight(self.state.bufnr, ns, "TelescopeResultsNumber", 0, 0, 10)
			-- Highlights time
			vim.api.nvim_buf_add_highlight(self.state.bufnr, ns, "TelescopeResultsIdentifier", 0, 11, -1)
			-- Highlights devicons
			for i, hl in ipairs(devicon_hls) do
				vim.api.nvim_buf_add_highlight(self.state.bufnr, ns, hl, i, 0, 3)
			end
		end,
		teardown = function(self)
			vim.api.nvim_buf_delete(self.state.bufnr, { force = true })
			self.state.bufnr = nil
		end,
	})
end

return M
