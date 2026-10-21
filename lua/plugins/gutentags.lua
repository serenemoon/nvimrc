-- vim-gutentags: 按项目自动生成 / 增量更新 ctags 索引
-- <leader>tt: 用 Snacks 列出当前文件的 tags（读取 gutentags 生成的 tags 文件）
-- <leader>tT: 列出当前仓库内所有文件的 tags
-- <leader>tf: 列出当前文件的函数 / 方法（优先 LSP，没有 LSP 时用 treesitter）

-- 用 state 而不是 cache：Windows 上 stdpath("cache") 位于 %TEMP%，容易被清理，
-- 清理后 gutentags 会对整个项目重新建索引。
local cache_dir = vim.fs.joinpath(vim.fn.stdpath("state"), "gutentags")
local ctags_exe = "ctags"
local project_roots = { ".git", ".hg", ".svn", ".root" }

local function current_file()
  local file = vim.api.nvim_buf_get_name(0)
  return file ~= "" and file or nil
end

-- taglist() 的第二个参数只是“优先显示这个文件”，并不会过滤掉其他文件。
-- Snacks 的 tags picker 同样用它做优先级，所以这里必须自己按文件名过滤。
local function same_file(a, b)
  if not a or not b or a == "" or b == "" then
    return false
  end
  -- Windows 大小写不敏感；统一分隔符后再比较。
  return vim.fs.normalize(a):lower() == vim.fs.normalize(b):lower()
end

-- 判断 path 是否位于 dir 内（包含 dir 本身）。
local function is_in_dir(path, dir)
  if not path or path == "" or not dir or dir == "" then
    return false
  end
  local p = vim.fs.normalize(path)
  local d = vim.fs.normalize(dir)
  if vim.fn.has("win32") == 1 then
    p = p:lower()
    d = d:lower()
  end
  return vim.fs.relpath(d, p) ~= nil
end

local function pick_tags()
  local file = current_file()
  if not file then
    vim.notify("当前缓冲区没有文件名，无法列出 tags", vim.log.levels.WARN)
    return
  end

  -- 先确认当前文件在 tags 文件里确实有条目，避免打开一个空 picker。
  local has_tags = false
  for _, tag in ipairs(vim.fn.taglist(".*")) do
    if same_file(tag.filename, file) then
      has_tags = true
      break
    end
  end

  if not has_tags then
    local hint = vim.fn.executable(ctags_exe) == 1 and "gutentags 可能还在生成索引，请稍后再试"
      or ("未找到 " .. ctags_exe .. "，请先安装 universal-ctags 并加入 PATH")
    vim.notify("当前文件没有 tags：" .. hint, vim.log.levels.WARN)
    return
  end

  Snacks.picker.tags({
    title = "Tags: " .. vim.fn.fnamemodify(file, ":t"),
    transform = function(item)
      -- 返回 false 会让 Snacks 跳过这个 item。
      return same_file(item.file, file) and item or false
    end,
  })
end

local function pick_repo_tags()
  local root = vim.fs.root(0, project_roots)
  if not root then
    vim.notify("当前文件不在项目仓库内，无法列出仓库 tags", vim.log.levels.WARN)
    return
  end

  local has_tags = false
  for _, tag in ipairs(vim.fn.taglist(".*")) do
    if is_in_dir(tag.filename, root) then
      has_tags = true
      break
    end
  end

  if not has_tags then
    local hint = vim.fn.executable(ctags_exe) == 1 and "gutentags 可能还在生成索引，请稍后再试"
      or ("未找到 " .. ctags_exe .. "，请先安装 universal-ctags 并加入 PATH")
    vim.notify("当前仓库没有 tags：" .. hint, vim.log.levels.WARN)
    return
  end

  Snacks.picker.tags({
    title = "Tags (repo): " .. vim.fs.basename(root),
    transform = function(item)
      return is_in_dir(item.file, root) and item or false
    end,
  })
end

local function pick_functions()
  local name = vim.fn.expand("%:t")
  local opts = {
    -- Snacks 的 symbol picker 用 LSP / treesitter 的 kind 名做过滤
    filter = { default = { "Function", "Method" } },
    tree = false,
    title = "Functions: " .. (name ~= "" and name or "[No Name]"),
  }

  if #vim.lsp.get_clients({ bufnr = 0 }) > 0 then
    Snacks.picker.lsp_symbols(opts)
  else
    Snacks.picker.treesitter(opts)
  end
end

return {
  {
    "ludovicchabant/vim-gutentags",
    -- gutentags 靠 autocmd 在打开/保存文件时建索引，必须随 Neovim 启动加载。
    -- （只写 keys 时 lazy.nvim 会自动把插件设成 lazy = true，这里显式覆盖）
    lazy = false,
    init = function()
      vim.g.gutentags_project_root = project_roots
      vim.g.gutentags_add_default_project_roots = 0

      -- tag 文件统一放到 state 目录，避免污染工程目录
      vim.g.gutentags_cache_dir = cache_dir
      vim.g.gutentags_ctags_executable = ctags_exe

      -- 不要通过 gutentags_ctags_extra_args 传 `--fields=+niazS` 这类带 `=` 的参数：
      -- &shell 为 PowerShell 时，PowerShell 会把参数在 `=` 处拆开再传给
      -- update_tags.cmd，ctags 会报 "Invalid Argument" 并直接退出，tags 文件不会生成。
      -- ctags 默认输出已经包含 Snacks tags picker 所需的字段，够用了。

      vim.g.gutentags_ctags_exclude = {
        ".git",
        ".repo",
        ".hg",
        ".svn",
        "node_modules",
        "vendor",
        "build",
        "dist",
        "out",
        "cache",
        "*.min.*",
        "*.lock",
        "*.svg",
        "tags",
        "TAGS",
        ".tags",
      }

      vim.g.gutentags_generate_on_new = 1
      vim.g.gutentags_generate_on_missing = 1
      vim.g.gutentags_generate_on_write = 1
      vim.g.gutentags_generate_on_empty_buffer = 0
      vim.g.gutentags_background_update = 1
      vim.g.gutentags_define_advanced_commands = 1

      vim.fn.mkdir(cache_dir, "p")

      -- 没有 ctags 时先禁用，避免每打开一个项目文件都弹错；装好后重启即可
      if vim.fn.executable(ctags_exe) == 0 then
        vim.g.gutentags_enabled = 0
        vim.schedule(function()
          vim.notify(
            "gutentags: 未找到 '"
              .. ctags_exe
              .. "'，已暂时禁用。请安装 universal-ctags（winget install --id UniversalCtags.Ctags -e）后重启 Neovim。",
            vim.log.levels.WARN
          )
        end)
      end
    end,
    keys = {
      { "<leader>tt", pick_tags, desc = "Tags (current file)" },
      { "<leader>tT", pick_repo_tags, desc = "Tags (repo)" },
      { "<leader>tf", pick_functions, desc = "Functions (current file)" },
    },
  },
}
