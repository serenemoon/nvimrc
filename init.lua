-- 打开 Neovim 时按需把 custom/ 下的模板分发到工程根目录
-- (.clang-format / .clang-tidy / .repo 的 .nvim.lua)
require("config.auto-copy")
-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
require("config.commands")
require("nvim-treesitter.install").prefer_git = true
