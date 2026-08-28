-- lua/plugins/disable-keymaps.lua
--
return {
  "LazyVim/LazyVim",
  keys = {
    { "<C-h>", false }, -- 禁用 Ctrl+hijk切换窗口
    { "<C-j>", false }, -- 禁用 Ctrl+h
    { "<C-k>", false }, -- 禁用 Ctrl+h
    { "<C-l>", false }, -- 禁用 Ctrl+h
  },
}
