-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
require("config.commands")
require("config.clangd")
require("nvim-treesitter.install").prefer_git = true
