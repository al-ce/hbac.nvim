local command = require("hbac.command")
local subcommands = require("hbac.command.subcommands")

local M = {
	setup = require("hbac.setup").setup,
	cmd = command.vim_cmd_func,
}

M = vim.tbl_extend("error", M, subcommands)

return M
