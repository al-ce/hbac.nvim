local command = require("hbac.command")
local subcommands = require("hbac.command.subcommands")

return {
	setup = require("hbac.setup").setup,
	cmd = command.vim_cmd_func,
	close_unpinned = subcommands.close_unpinned,
	pin_picker = subcommands.pin_picker,
	pin_all = subcommands.pin_all,
	unpin_all = subcommands.unpin_all,
	store_pinned_bufs = subcommands.store_pinned_bufs,
	storage_picker = subcommands.storage_picker,
	toggle_autoclose = subcommands.toggle_autoclose,
	toggle_pin = subcommands.toggle_pin,
}
