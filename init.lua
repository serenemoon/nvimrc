-- 打开 Neovim 时按需生成 .repo 根目录下的 .nvim.lua
require("config.config-local")
-- 打开 Neovim 时按需把 custom/ 下的 .clang-format / .clang-tidy 拷到 .repo 根目录
require("config.auto-copy")
-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
require("config.commands")
require("nvim-treesitter.install").prefer_git = true
