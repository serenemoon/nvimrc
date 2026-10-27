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

--- 判断给定 buffer 或文件是否在 repo 目录下。
--- repo 目录指:向上查找到的第一个包含 `.repo` 的目录,且该目录本身
--- 以及其中的 `.repo` 都是真实目录。
--- @param target integer|string buffer 编号,或文件路径
--- @return boolean
function M.is_file_in_repo(target)
  local root = vim.fs.root(target, ".repo")
  if not root then
    return false
  end
  return vim.fn.isdirectory(root) == 1 and vim.fn.isdirectory(vim.fs.joinpath(root, ".repo")) == 1
end

--- 取当前要搜索的目标文本:处于 visual(x)模式且选区在单行内时返回选中的字符串,
--- 否则(非 visual,或选区跨多行)返回光标下的符号(<cword>)。
--- @return string text 目标文本
--- @return boolean from_visual text 是否来自 visual 选区
function M.search_target()
  local mode = vim.fn.mode()
  if mode == "v" or mode == "V" or mode == "\22" then
    -- 在 x 模式映射里 visualmode() 冷启动可能为空(会触发 E475),用 mode() 作为选区类型
    local s = vim.fn.getpos("v")
    local e = vim.fn.getpos(".")
    if s[2] > e[2] or (s[2] == e[2] and s[3] > e[3]) then
      s, e = e, s
    end
    -- 仅支持单行内的 visual 选择,跨行时退回 <cword>
    if s[2] == e[2] then
      return table.concat(vim.fn.getregion(s, e, { type = mode }), "\n"), true
    end
  end
  return vim.fn.expand("<cword>"), false
end

--- 把文本转成 snacks picker 的 pattern,配合 matcher.fuzzy = false 做按字面匹配。
--- 普通标识符原样返回(输入框里显示干净);含空白、冒号,或首尾是 `!`/`^`/`'`/`$`
--- 这类会被 matcher 当成语法的字符时,改用 `\V` 字面正则并切到 regex 模式。
--- @param text string
--- @return string pattern
--- @return boolean use_regex 是否需要 matcher.regex = true
function M.search_pattern(text)
  local plain = not text:find("[%s:]") and not text:match("^[!'^]") and text:sub(-1) ~= "$"
  if plain then
    return text, false
  end
  local pattern = [[\V]] .. text:gsub("\\", "\\\\")
  return text == text:lower() and ([[\c]] .. pattern) or pattern, true
end

function M.is_win()
  return vim.fn.has("win32") or vim.fn.has("win64")
end

return M
