# ObsidianTools

ObsidianTools is designed to enhance the management of tags and notes within Obsidian. The plugin provides functionalities to create notes, manage tags, and integrate with other Neovim plugins.

## Features

-  Create Obsidian notes from within Neovim.
-  Manage tags efficiently, including adding tags to metadata.
-  Integrate with Telescope for better tag navigation and selection.
-  Use customizable keymaps for seamless workflow.
-  Process markdown files to convert inline hashtags to tag metadata.

## Setup

### Requirements

-  Neovim
-  Obsidian plugin for Neovim

### Installation

```lua
-- in lazy
{
    'yourusername/ObsidianTools',
    config = function()
        require('ObsidianTools').setup({
            workspacePath = '/absolute/path/to/obsidian/workspace',
            tagListsFile = '/absolute/path/to/tag_lists.lua',
        })
    end,
})
