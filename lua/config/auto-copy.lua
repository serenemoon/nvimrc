-- 打开 Neovim 时，从当前路径向上查找工程根目录，把 nvim 配置目录 custom/ 下的
-- 模板分发过去（clang 配置、.repo 的 .nvim.lua 等）。
local M = {}

-- 分发规则：
--   src     相对 custom/ 的模板文件名
--   dst     目标文件名(缺省与 src 同名)
--   markers 该文件需要的「根目录标记」：外层列表依次尝试，取第一个命中的目录；
--           内层列表要求该目录同时含有其中所有 marker。
local COPY_RULES = {
  { src = ".clang-format", markers = { { ".repo" }, { ".git", "CMakeLists.txt" } } },
  { src = ".clang-tidy", markers = { { ".repo" }, { ".git", "CMakeLists.txt" } } },
  { src = ".repo.nvim.lua", dst = ".nvim.lua", markers = { { ".repo" } } },
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
  for _, rule in ipairs(COPY_RULES) do
    local root = find_root(rule.markers)
    if root then
      local src = vim.fs.joinpath(custom_dir, rule.src)
      local dst = vim.fs.joinpath(root, rule.dst or rule.src)
      local src_stat = vim.uv.fs_stat(src)
      local dst_stat = vim.uv.fs_stat(dst)

      if not src_stat then
        vim.notify("缺少模板文件: " .. src, vim.log.levels.WARN)
      elseif dst_stat and dst_stat.size == src_stat.size then
        -- 目标已存在且与模板大小一致，视为已分发，跳过
      elseif vim.uv.fs_copyfile(src, dst) then
        vim.notify((dst_stat and "已更新 " or "已生成 ") .. dst, vim.log.levels.INFO)
      end
    end
  end
end

vim.api.nvim_create_autocmd("VimEnter", {
  callback = M.install,
})

return M
