-- 打开 Neovim 时，从当前路径向上查找 .repo 根目录；
-- 若该根目录下不存在 .nvim.lua，则把 nvim 配置目录里的模板
-- config-local/.repo.nvim.lua 复制过去并改名为 .nvim.lua。
local M = {}

local template = vim.fs.joinpath(vim.fn.stdpath("config"), "config-local", ".repo.nvim.lua")

function M.install()
  local repo = vim.fs.root(vim.fn.getcwd(), ".repo")
  if not repo then
    return
  end

  local target = vim.fs.joinpath(repo, ".nvim.lua")
  if vim.uv.fs_stat(target) then
    return
  end

  if vim.fn.filereadable(template) ~= 1 then
    vim.notify("缺少模板文件: " .. template, vim.log.levels.WARN)
    return
  end

  if vim.uv.fs_copyfile(template, target) then
    vim.notify("已生成 " .. target, vim.log.levels.INFO)
  end
end

vim.api.nvim_create_autocmd("VimEnter", {
  callback = M.install,
})

return M
