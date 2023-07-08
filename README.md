# hbac.nvim
Heuristic buffer auto-close
# overview
Automagically close the unedited buffers in your bufferlist when it becomes too long. The "edited" buffers remain untouched. For a buffer to be considered edited it is enough to enter insert mode once or modify it in any way.

# description
You like using the buffer list, but you hate it when it has too many buffers, because you loose the overview for what files you are *actually* working on. Indeed, a lot of the times, when browsing code you want to look at some files, that you are not actively working on, like checking the definitions or going down the callstack when debugging. These files then pollute the bufferlist and make it harder to find ones you actually care about.
Reddit user **xmsxms** [posted](https://www.reddit.com/r/neovim/comments/12c4ad8/closing_unused_buffers/?utm_source=share&utm_medium=web2x&context=3) a script that marks all once edited files in a session as important and provides a keybinding to close all the rest. In fact, I used some of his code in this plugin, and you can achieve the same effect as his script using hbac.
The main feature of this plugin, however, is the automatic closing of buffers. If the number of buffers reaches a threshold (default is 10), the oldest unedited buffer will be closed once you open a new one.

https://github.com/al-ce/hbac.nvim/assets/23170004/18901c60-b732-47be-93a7-e5acdb4ce53d

# installation

with [packer.nvim](https://github.com/wbthomason/packer.nvim)
```lua
use {
  'axkirillov/hbac.nvim',
  requires = {
  -- these are optional, add them, if you want the telescope module
    'nvim-telescope/telescope.nvim',
    'nvim-lua/plenary.nvim',
    'nvim-tree/nvim-web-devicons'
    }
}
```
with [lazy.nvim](https://github.com/folke/lazy.nvim)
```lua
{
  'axkirillov/hbac.nvim',
  dependencies = {
  -- these are optional, add them, if you want the telescope module
    'nvim-telescope/telescope.nvim',
    'nvim-lua/plenary.nvim',
    'nvim-tree/nvim-web-devicons'
  },
  config = function ()
    require("hbac").setup()
  end
}
```

# configuration

```lua
local opts = {
  autoclose = true,
  threshold = 10,
  close_buffers_with_windows = false,
  close_command = function(bufnr)
    vim.api.nvim_buf_delete(bufnr, {})
  end,
  notify = true,  -- show or hide notifications on Hbac actions
  storage = {
    open = {
      prehook = function() end, -- called before any stored pins are opened
      command = function(pin) -- this is called on each item in storage while iterating
        vim.cmd("e " .. pin.abs_path)
        local bufnr = vim.fn.bufnr()
        require("hbac.state").pinned_buffers[bufnr] = true  -- used to prevent autoclose from closing the buffer
      end,
      posthook = function() end,  -- called after all stored pins are opened
    },
    -- add custom commands with similar pre/posthook + command structure
  },
  telescope = {
    pin_picker = {
      mappings = {
        n = {
          close_unpinned = "<M-c>",
          delete_buffer = "<M-x>",
          pin_all = "<M-a>",
          unpin_all = "<M-u>",
          toggle_selections = "<M-y>",
          store_pinned_bufs = "<M-s>",
          add_buf_to_storage = "<M-b>",
        },
        i = {
          -- as above
        },
      },
      -- Pinned/unpinned icons and their hl groups. Defaults to nerdfont icons
      pin_icons = {
        pinned = { "󰐃 ", hl = "DiagnosticOk" },
        unpinned = { "󰤱 ", hl = "DiagnosticError" },
      },
    },
    storage_picker = {
      mappings = {
        n = {
          open_stored_pins = "<CR>",
          delete_stored_pins = "<M-x>",
          rename_stored_pins = "<M-r>",
          clear_pin_storage = "<M-d>",
          preview_stored_pins = "<C-p>",
          update_stored_pins = "<M-u>",
          add_cur_buf_to_entry = "<M-b>",
          exec_command_on_pins = "<M-e>",
        },
        i = {
          -- as above
        },
      },
    },
  },
},

require("hbac").setup(opts)
```

# usage
Let hbac do its magick 😊

or

- `:Hbac toggle_pin` - toggle a pin of the current buffer to prevent it from being auto-closed
- `:Hbac close_unpinned` - close all unpinned buffers
- `:Hbac pin_all` - pin all buffers
- `:Hbac unpin_all` - unpin all buffers
- `:Hbac toggle_autoclose` - toggle autoclose behavior
- `:Hbac pin_picker` - open the telescope picker to manage the pin states of buffers
- `:Hbac store_pinned_bufs` - store the currently pinned bufs in a JSON file
- `:Hbac storage_picker` - open the telescope picker to load/delete stored pins

or, if you prefer to use lua:
```lua
local hbac = require("hbac")
hbac.toggle_pin()
hbac.close_unpinned()
hbac.pin_all()
hbac.unpin_all()
hbac.toggle_autoclose()
hbac.pin_picker()
hbac.store_pinned_bufs()  -- no arg prompts for an entry name. Pass a string to
                          -- skip the prompt or update an existing entry
hbac.storage_picker()
```

## Telescope integration

The plugin provides [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) integration for the pin state management and storing and loading pinned buffers.
This requires telescope and its dependency [plenary.nvim](https://github.com/nvim-lua/plenary.nvim). We also recommend [nvim-web-devicons](https://github.com/nvim-tree/nvim-web-devicons).

### Telescope: Pin Picker

Views and manage the pin states of buffers. The picker provides the following actions:

- `hbac_toggle_selections` - toggle the pin state of the selected buffers (either
  single or multi-selections). This is the default action (typically `<CR>`)
- `hbac_pin_all` - pin all buffers. Default `<M-a>`
- `hbac_unpin_all` - unpin all buffers. Default `<M-u>`
- `hbac_close_unpinned` - close all unpinned buffers. Default `<M-c>`
- `hbac_delete_buffer` - delete the selected buffers with the function set in `opts.close_command` (`nvim_buf_delete` by default`). Default `<M-x>`
- `hbac_store_pinned_bufs` - store the currently pinned buffers in a JSON file. See section below for details. Default `<M-s>`
- `hbac_add_buf_to_storage` - add the current buffer to a stored entry by selecting the entry from a new picker. Default `<M-b>`

You can also call the picker function directly and pass a table of options (see `:h telescope.setup()` for valid option keys):

```lua
require("hbac.telescope").pin_picker({
  layout_strategy = "horizontal",
  initial_mode = "normal",
  -- etc.
})
```

https://github.com/al-ce/hbac.nvim/assets/23170004/b9686a4d-7656-4220-a32c-6193517a2009

### Telescope: Storage Picker

You can save the filepath and related data of multiple sets of pinned buffers in a JSON file. This allows you to quickly load and restore pinned buffers for different projects or workflows.

You can store pins with either the `:Hbac store_pinned_bufs` command or the `hbac_store_pinned_bufs` action in the pin picker (default `<M-s>`). Either one will prompt you for a name for the set of pins. If the name already exists as a key in the JSON file, you will be asked to confirm the overwrite.

The storage picker lets you view, load, or delete sets of stored pins. In the picker's previewer, you will see the date the pins were stored and the files that were pinned, including their paths relative to the project root they were stored from.

The storage picker provides the following actions:

- `hbac_open_stored_pins` - open the selected set of stored pins. Default `<CR>`
- `hbac_delete_stored_pins` - delete the selected set of stored pins (with confirmation). Default `<M-x>`
- `hbac_rename_stored_pins` - rename the selected set of stored pins. Default `<M-r>`
- `hbac_clear_pin_storage` - delete all stored pins (with confirmation). Default `<M-d>`
- `hbac_preview_stored_pins` - open a new picker to preview the selected set of stored pins. `<Esc>` will close the previewer and return to the storage picker. `<CR>` will open the file being previewed. The results from this picker can be sent to the quickfix list or a trouble window with `<C-t>`. Default `<C-p>` to start the preview-picker.
- `hbac_update_stored_pins` - update the selected stored pins entry with the currently pinned buffers. Default `<M-u>`.
- `hbac_add_cur_buf_to_entry` - add the current buffer to the selected storage entries. Default `<M-b>`
- `hbac_exec_command_on_pins` - execute a command over all the selected stored pin entries by selecting the command from a new picker. Default `<M-e>`

Note that most of these actions are exposed functions in the `hbac.storage` module and can be called directly, but the storage picker makes it easy to visualize them.


https://github.com/al-ce/hbac.nvim/assets/23170004/f090dc63-addc-4284-919c-13d6658ca6ea


### Pre- / Posthook and actions on stored pins

You can define custom actions to be performed over all the pins in a selected
storage entry. (see demo video above)

You can define pre- and posthooks for a custom action in the `storage` option table. These hooks are called before and after the stored pins are opened. You can use them to close unpinned buffers, open a new tab, or whatever you like.

The `command` function is called during the loop that iterates over the stored pins in an entry. It is called after the prehook and before the posthook. The default is to simply open the file and pin its buffer.

These actions are added in your setup opts. For example:

```lua
      local hbac = require("hbac")
      hbac.setup({
        storage = {
          -- This is the only default action, and it can be overridden
          -- It will unpin all current buffers in the prehook, then open the
          --files (pins) in the selected entry, then close all unpinned buffers
          -- (i.e. all previously opened buffers that were not in the entry))
          -- in the posthook
          open = {
            prehook = function()
              hbac.unpin_all()
            end,
            command = function(pin)
              vim.cmd("e " .. pin.abs_path)
              hbac.toggle_pin()
            end,
            posthook = function()
              hbac.close_unpinned()
            end,
          },
          -- Unlike the default open action, this action ensures that all
          -- currently opened files will remain open after opening the pins
          -- by setting the autoclose_enabled flag to false in the prehook
          append_bufs = {
            prehook = function()
              require("hbac.state").autoclose_enabled = false
              -- You could also open all the pins in a new tab
              -- vim.cmd("Hbac close_unpinned")
            end,
            command = function(pin)
              vim.cmd("e " .. pin.abs_path)
            end,
          },
          -- This action simply appends the paths of the pins to a log file,
          -- without opening them
          log_file_paths = {
            command = function(pin)
              vim.cmd("!echo '" .. pin.abs_path .. "' >> ~/tmp/my_paths.log")
            end,
          },
        },
      })
```

## Other ways to view the pin status of buffers

The `state` module exposes the `is_pinned` function, which returns the pin status of any buffer as a boolean value. You can use this check to display the pin status in your statusline or wherever you find convenient. Here is an example [lualine.nvim](https://github.com/nvim-lualine/lualine.nvim) integration:

```lua
lualine_c = {
    {
    function()
        local cur_buf = vim.api.nvim_get_current_buf()
        return require("hbac.state").is_pinned(cur_buf) and "📍" or ""
        -- tip: nerd fonts have pinned/unpinned icons!
      end,
      color = { fg = "#ef5f6b", gui = "bold" },
    }
  }
```
