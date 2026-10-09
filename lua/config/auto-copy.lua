-- 打开 Neovim 时，从当前路径向上查找 .repo 根目录；
-- 若找到，且该根目录下缺少这些文件，则从 nvim 配置目录的 custom/ 拷贝过去。
local M = {}

-- 需要分发到 .repo 根目录的文件（相对 custom/ 的文件名）
local FILES = { ".clang-format", ".clang-tidy" }

local custom_dir = vim.fs.joinpath(vim.fn.stdpath("config"), "custom")

function M.install()
  local repo = vim.fs.root(vim.fn.getcwd(), ".repo")
  if not repo then
    return
  end

  for _, name in ipairs(FILES) do
    local src = vim.fs.joinpath(custom_dir, name)
    local dst = vim.fs.joinpath(repo, name)
    if vim.uv.fs_stat(dst) then
      -- 目标已存在，跳过，不覆盖用户自己的配置
      goto continue
    end
    if vim.fn.filereadable(src) ~= 1 then
      vim.notify("缺少模板文件: " .. src, vim.log.levels.WARN)
      goto continue
    end
    if vim.uv.fs_copyfile(src, dst) then
      vim.notify("已生成 " .. dst, vim.log.levels.INFO)
    end
    ::continue::
  end
end

vim.api.nvim_create_autocmd("VimEnter", {
  callback = M.install,
})

return M
