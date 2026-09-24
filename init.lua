-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.commands")
require("config.lazy")
require("nvim-treesitter.install").prefer_git = true
