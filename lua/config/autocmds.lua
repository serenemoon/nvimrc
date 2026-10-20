-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- repo 目录下的文件不自动格式化
vim.api.nvim_create_autocmd("BufEnter", {
  group = vim.api.nvim_create_augroup("user_no_autoformat_in_repo", { clear = true }),
  callback = function(args)
    if require("config.util").is_file_in_repo(args.buf) then
      vim.b.autoformat = false
    end
  end,
})
