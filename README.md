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
      -- pre- and posthook are called before/after stored pins are opened
      prehook = function()
        -- local close_unpinned = require("hbac.command.subcommands").close_unpinned
        -- close_unpinned()
        -- vim.cmd("tabnew")
      end,
      posthook = function() end,
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
hbac.store_pinned_bufs()
hbac.storage_picker()
```

## Telescope integration

The plugin provides [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) integration for the pin state management and storing and loading pinned buffers.
This requires telescope and its dependency [plenary.nvim](https://github.com/nvim-lua/plenary.nvim). We also recommend [nvim-web-devicons](https://github.com/nvim-tree/nvim-web-devicons).

### Pin Picker

Views and manage the pin states of buffers. The picker provides the following actions:

- `hbac_toggle_selections` - toggle the pin state of the selected buffers (either
  single or multi-selections)
- `hbac_pin_all` - pin all buffers
- `hbac_unpin_all` - unpin all buffers
- `hbac_close_unpinned` - close all unpinned buffers
- `hbac_delete_buffer` - delete the selected buffers with the function set in `opts.close_command` (`nvim_buf_delete` by default`)
- `hbac_store_pinned_bufs` - store the currently pinned buffers in a JSON file. See section below for details.

You can also call the picker function directly and pass a table of options (see `:h telescope.setup()` for valid option keys):

```lua
require("hbac.telescope").pin_picker({
  layout_strategy = "horizontal",
  initial_mode = "normal",
  -- etc.
})
```

https://github.com/al-ce/hbac.nvim/assets/23170004/b9686a4d-7656-4220-a32c-6193517a2009

### Storage Picker

You can save the filepath and related data of multiple sets of pinned buffers in a JSON file. This allows you to quickly load and restore pinned buffers for different projects or workflows.

You can store pins with either the `:Hbac store_pinned_bufs` command or the `hbac_store_pinned_bufs` action in the pin picker (default `<M-s>`). Either one will prompt you for a name for the set of pins. If the name already exists as a key in the JSON file, you will be asked to confirm the overwrite.

The storage picker lets you view, load, or delete sets of stored pins. In the
picker's previewer, you will see the date the pins were stored and the files that were pinned, including their paths relative to the project root they were stored from.

The picker provides the following actions:

- `hbac_open_stored_pins` - open the selected set of stored pins
- `hbac_delete_stored_pins` - delete the selected set of stored pins (with confirmation)


https://github.com/al-ce/hbac.nvim/assets/23170004/17948123-2f2d-4070-89b7-334fcff656e6

#### Pre- and Posthooks

You can define pre- and posthooks for the `open` action in the `storage` option table. These hooks are called before and after the stored pins are opened. You can use them to close unpinned buffers, open a new tab, or whatever you like.

```lua
require("hbac").setup({
  storage = {
    open = {
      prehook = function()
        -- set all buffers to unpinned
        -- [[some function to do that]]
        require("hbac.command.subcommands").close_unpinned()
        vim.cmd("tabnew")
      end,
      posthook = function()
        -- maybe open the pin picker, run some command in the terminal, etc.
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
