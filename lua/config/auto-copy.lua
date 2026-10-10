-- 打开 Neovim 时，从当前路径向上查找 .repo 根目录；找不到则回退查找 .git。
-- 若找到，且该根目录下缺少这些文件，则从 nvim 配置目录的 custom/ 拷贝过去。
local M = {}

-- 每个要分发的文件对应一组「根目录标记」：外层列表依次尝试，取第一个命中的目录；
-- 内层列表要求该目录同时含有其中所有 marker。键为相对 custom/ 的文件名。
local COPY_RULES = {
  [".clang-format"] = { { ".repo" }, { ".git", "CMakeLists.txt" } },
  [".clang-tidy"] = { { ".repo" }, { ".git", "CMakeLists.txt" } },
}

local custom_dir = vim.fs.joinpath(vim.fn.stdpath("config"), "custom")

--- 判断 dir 是否同时含有 markers 中的全部标记。
--- @param dir string
--- @param markers string[]
--- @return boolean
local function has_all_markers(dir, markers)
  for _, marker in ipairs(markers) do
    if vim.uv.fs_stat(vim.fs.joinpath(dir, marker)) == nil then
      return false
    end
  end
  return true
end

--- 从 cwd 向上逐级查找，返回第一个满足 groups 中某一组 markers 的目录。
--- @param groups string[][]
--- @return string|nil
local function find_root(groups)
  for dir in vim.fs.parents(vim.fn.getcwd()) do
    for _, markers in ipairs(groups) do
      if has_all_markers(dir, markers) then
        return dir
      end
    end
  end
  return nil
end

function M.install()
  local names = vim.tbl_keys(COPY_RULES)
  table.sort(names)
  for _, name in ipairs(names) do
    local root = find_root(COPY_RULES[name])
    if root then
      local src = vim.fs.joinpath(custom_dir, name)
      local dst = vim.fs.joinpath(root, name)
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
    end
    ::continue::
  end
end

vim.api.nvim_create_autocmd("VimEnter", {
  callback = M.install,
})

return M
