-- 通用辅助函数
local M = {}

--- 当前 buffer 所在目录;没有打开文件(缓冲区无文件名)时回退到进程 cwd。
--- @return string
local function current_dir()
  local file = vim.api.nvim_buf_get_name(0)
  if file ~= "" then
    return vim.fn.fnamemodify(file, ":h")
  end
  return vim.fn.getcwd()
end

--- 从当前文件向上查找根目录。
--- @param opts table 数组部分为一组根目录标记(按顺序尝试),另可带 `dfs = true`。
---   例:{ ".repo", ".git", dfs = true }
---   dfs=true 时逐个 marker 依次查找,false/nil 时交给 vim.fs.root 一次查找。
--- @return string 命中的根目录;找不到时回退到当前文件所在目录,无文件则回退 cwd。
function M.find_root(opts)
  local markers = {}
  for _, marker in ipairs(opts) do
    markers[#markers + 1] = marker
  end
  local fallback = current_dir()
  if opts.dfs then
    for _, marker in ipairs(markers) do
      local root = vim.fs.root(0, marker)
      if root then
        return root
      end
    end
    return fallback
  end
  return vim.fs.root(0, markers) or fallback
end

return M
