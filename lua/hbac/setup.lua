local hbac_state = require("hbac.state")

local pin_picker_mappings = {
	close_unpinned = "<M-c>",
	delete_buffer = "<M-x>",
	pin_all = "<M-a>",
	unpin_all = "<M-u>",
	toggle_selections = "<M-y>",
	store_pinned_bufs = "<M-s>",
	add_buf_to_storage = "<M-b>",
}

local storage_picker_mappings = {
	open_stored_pins = "<CR>",
	delete_stored_pins = "<M-x>",
	rename_stored_pins = "<M-r>",
	clear_pin_storage = "<M-d>",
	preview_stored_pins = "<C-p>",
	update_stored_pins = "<M-u>",
	add_cur_buf_to_entry = "<M-b>",
	exec_command_on_pins = "<M-e>",
}

local M = {
	opts = {
		autoclose = true,
		threshold = 10,
		close_buffers_with_windows = false,
		close_command = function(bufnr)
			vim.api.nvim_buf_delete(bufnr, {})
		end,
		notify = true,
		storage = {
			open = {
				prehook = function() end,
				command = function(pin)
					vim.cmd("e " .. pin.abs_path)
					local bufnr = vim.fn.bufnr()
					hbac_state.pinned_buffers[bufnr] = true
				end,
				posthook = function() end,
			},
		},
		telescope = {
			pin_picker = {
				mappings = {
					n = pin_picker_mappings,
					i = pin_picker_mappings,
				},
				pin_icons = {
					pinned = { "󰐃 ", hl = "DiagnosticOk" },
					unpinned = { "󰤱 ", hl = "DiagnosticError" },
				},
			},
			storage_picker = {
				mappings = {
					n = storage_picker_mappings,
					i = storage_picker_mappings,
				},
			},
		},
	},
}

local id = vim.api.nvim_create_augroup("hbac", {
	clear = false,
})

M.setup = function(user_opts)
	local command = require("hbac.command")
	M.opts = vim.tbl_deep_extend("force", M.opts, user_opts or {})

	vim.api.nvim_create_autocmd({ "BufRead" }, {
		group = id,
		pattern = { "*" },
		callback = function()
			vim.api.nvim_create_autocmd({ "InsertEnter", "BufModifiedSet" }, {
				buffer = 0,
				callback = function()
					local bufnr = vim.api.nvim_get_current_buf()
					if hbac_state.is_pinned(bufnr) then
						return
					end
					hbac_state.toggle_pin(bufnr)
				end,
			})
		end,
	})

	vim.api.nvim_create_user_command(command.vim_cmd_name, function(args)
		command.vim_cmd_func(args.args)
	end, command.vim_cmd_opts)

	if M.opts.autoclose then
		require("hbac.autocommands").autoclose.setup()
	end
end

return M
