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
      fill_windows = true,  -- set to true to spread the stored pins across windows when opening
      prehook = function() end, -- called before any stored pins are opened
      on_open = function(pin) -- this is called on each item in storage while iterating
        vim.cmd("e " .. pin.abs_path)
        local bufnr = vim.fn.bufnr()
        require("hbac.state").pinned_buffers[bufnr] = true  -- used to prevent autoclose from closing the buffer
      end,
      posthook = function() end,  -- called after all stored pins are opened
    },
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
- `hbac_preview_stored_pins` - open a new picker to preview the selected set of stored pins. `<Esc>` will close the previewer and return to the storage picker. The results from this picker can be sent to the quickfix list or a trouble window. Default `<C-p>`
- `hbac_update_stored_pins` - update the selected stored pins entry with the currently pinned buffers. Default `<M-u>`.
- `hbac_add_cur_buf_to_entry` - add the current buffer to the selected storage entries. Default `<M-b>`

Note that most of these actions are exposed functions in the `hbac.storage` module and can be called directly, but the storage picker makes it easy to handle all these actions.

https://github.com/al-ce/hbac.nvim/assets/23170004/17948123-2f2d-4070-89b7-334fcff656e6

## Pre- / Posthook, on_open functions

You can define pre- and posthooks for the `open` action in the `storage` option table. These hooks are called before and after the stored pins are opened. You can use them to close unpinned buffers, open a new tab, or whatever you like.

The `on_open` function is called during the loop that iterates over the stored pins in an entry. It is called after the prehook and before the posthook. The default is to simply open the file and pin its buffer.

Here are some minor changes to the defaults that you might find useful:

```lua
require("hbac").setup({
  storage = {
    open = {
      prehook = function()
        vim.cmd("Hbac close_unpinned")
        vim.cmd("tabnew")
      end,

      on_open = function(pin)
        vim.cmd("e " .. pin.abs_path)
        local bufnr = vim.fn.bufnr()
        require("hbac.state").pinned_buffers[bufnr] = true
      end,

      posthook = function()
        vim.cmd("Hbac pin_picker")
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
