-- 打开 Neovim 时按需生成 .repo 根目录下的 .nvim.lua
require("config.config-local")
-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
require("config.commands")
require("nvim-treesitter.install").prefer_git = true
