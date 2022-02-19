# TaskRun

This is a task runner plugin, which uses toggleterm to run shell commands.

![screenshot](https://user-images.githubusercontent.com/8683947/154804528-8fe917c0-3f98-4718-9d41-594d074c750b.png)

## Installation

```lua
use({'akinsho/toggleterm.nvim'})
use({'yutkat/taskrun.nvim',
  config = function() require("taskrun").setup() end})

-- Recommend
use({'rcarriga/nvim-notify'})
```

## Usage

```
:TaskRun ls
```

**Note: This plugin occupies terminal 9 of toggleterm**
