local M = {}

function M.open_focus_close(dir)
  -- 获取当前 explorer 实例
  local explorer = Snacks.picker.get({ source = "explorer" })[1]

  if explorer == nil then
    -- 情况1：没有打开任何 explorer -> 打开一个新的
    Snacks.picker.explorer({ cwd = dir })
  elseif explorer:is_focused() then
    -- 情况2：焦点已经在 explorer 上 -> 关闭它（或执行其他操作）
    Snacks.picker.explorer() -- 这会 toggle 关闭 explorer
  else
    -- 情况3：explorer 已打开但未聚焦 -> 将焦点切换过去
    explorer:set_cwd(dir or vim.fn.getcwd())
    explorer:find()
    explorer:focus()
  end
end

--- Ask `repo list -p -f` in `root` for every project worktree of this repo.
--- @param root string `.repo` root
--- @return string[]? repos nil when `repo` is unavailable or printed nothing
local function repo_list_repos(root)
  if vim.fn.executable("repo") ~= 1 then
    return nil
  end

  local ok, proc = pcall(vim.system, { "repo", "list", "-p", "-f" }, { cwd = root, text = true })
  if not ok then
    return nil
  end
  local res = proc:wait()
  if res.code ~= 0 then
    return nil
  end

  local repos, seen = {}, {}
  for _, line in ipairs(vim.split(res.stdout or "", "\n")) do
    -- `-p` prints "<path> : <project>"; older versions may print a bare path.
    local dir = vim.trim(vim.trim(line):match("^(.-)%s*:") or line)
    if dir ~= "" and not seen[dir] and vim.fn.isdirectory(dir) == 1 then
      seen[dir] = true
      repos[#repos + 1] = dir
    end
  end

  if #repos == 0 then
    return nil
  end
  table.sort(repos)
  return repos
end

--- Recursively scan `root` for git repositories, i.e. directories containing a
--- `.git` directory. Git objects are pruned so the walk stays cheap.
--- @param root string
--- @return string[] repos parent directory of every `.git`, sorted
local function scan_git_repos(root)
  local out, seen = {}, {}
  local function add(dir)
    if dir ~= "" and not seen[dir] then
      seen[dir] = true
      out[#out + 1] = dir
    end
  end

  if vim.fn.executable("fd") == 1 then
    for _, line in ipairs(vim.fn.systemlist({ "fd", "-u", "-t", "d", "--prune", "^%.git$", root })) do
      add(vim.fn.fnamemodify(line, ":h"))
    end
  elseif vim.fn.executable("find") == 1 then
    for _, line in ipairs(vim.fn.systemlist({ "find", root, "-type", "d", "-name", ".git", "-prune" })) do
      add(vim.fn.fnamemodify(line, ":h"))
    end
  else
    for _, line in
      ipairs(vim.fs.find(function(name)
        return name == ".git"
      end, { path = root, type = "directory", limit = math.huge }))
    do
      add(vim.fn.fnamemodify(line, ":h"))
    end
  end

  table.sort(out)
  return out
end

--- List the project worktrees under the `.repo` root of `filepath`.
--- `repo list -p -f` is preferred; a filesystem scan of `.git` directories is
--- used when `repo` is unavailable or fails. The result is cached in
--- `<repo>/.repo_gits` and reused when that file exists.
--- @param filepath string current file path
--- @param refresh? boolean ignore the cache and rescan
--- @return string[]|nil repos nil when no `.repo` root encloses `filepath`
function M.git_repos(filepath, refresh)
  local repo = vim.fs.root(filepath, ".repo")
  if not repo then
    return nil
  end

  local cache = repo .. "/.repo_gits"
  if not refresh and vim.fn.filereadable(cache) == 1 then
    local repos = {}
    for _, line in ipairs(vim.fn.readfile(cache)) do
      line = vim.trim(line)
      if line ~= "" then
        repos[#repos + 1] = line
      end
    end
    return repos
  end

  -- prefer the repo manifest; fall back to a filesystem scan
  local repos = repo_list_repos(repo) or scan_git_repos(repo)
  vim.fn.writefile(repos, cache)
  return repos
end

--- List the git repositories under the `.repo` root of the current file in a
--- picker. Confirming an entry opens it in the snacks explorer.
--- @param refresh? boolean ignore the `.repo_gits` cache and rescan
function M.pick_git_repos(refresh)
  local filepath = vim.api.nvim_buf_get_name(0)
  local repo = vim.fs.root(filepath, ".repo")
  if not repo then
    vim.notify("No .repo directory found", vim.log.levels.WARN)
    return
  end
  local repos = M.git_repos(filepath, refresh)
  if not repos or #repos == 0 then
    vim.notify("No git directories found under repo root", vim.log.levels.WARN)
    return
  end
  Snacks.picker.pick({
    source = "git_repos",
    -- set cwd to the repo root so the picker shows repo-relative paths
    cwd = repo,
    items = vim.tbl_map(function(dir)
      return { text = dir:sub(#repo + 2), file = dir, dir = true }
    end, repos),
    format = "file",
    preview = "none",
    confirm = function(picker, item)
      picker:close()
      if item then
        M.open_focus_close(item.file)
      end
    end,
  })
end

local CAMHAL = {
  "vendor/hisi/ap/hardware/camera_hal",
  "vendor/hisi/ap/include/camera_hal",
  "vendor/hisi/ap/hardware/camera_product",
}
local IPS = {
  "vendor/huawei/foundation/multimedia/algorithm_camera",
  "vendor/huawei/chipset/modules/camera_x",
}
local FFRT = "vendor/hisi/ffrt/basesrc"
local UAPI = "vendor/hisi/ap/bionic/libc/kernel/uapi"
local APKERNEL = "vendor/hisi/ap/kernel"
local HWKERNEL = "vendor/huawei/extra/kernel"
local KERNEL = "kernel/linux-6.6-lts"
local ISP = { "vendor/hisi/include/isp", "vendor/hisi/isp" }
local HISIODM = "vendor/hisi/odm"
local HISIDTS = "device/hisi/customize"
local OHOS_CAMERA_FWK = {
  "drivers/interface/camera",
  "foundation/multimedia/camera_framework",
  "foundation/multimedia/image_framework",
  "foundation/multimedia/image_effect",
}
local HELPSFWK = "vendor/huawei/base/hiviewdfx/helps_fwk"
local HWJS = "vendor/huawei/interface/hmscore_sdk_js"
local AOSP_CAMERA_FWK = {
  "hardware/interfaces/camera",
  "frameworks/av/services/camera",
  "frameworks/av/camera",
  "system/media/camera",
}

--- 判断 rel 是否位于相对目录 prefix 之下(含自身)。
local function is_under(rel, prefix)
  return rel == prefix or rel:sub(1, #prefix + 1) == prefix .. "/"
end

--- 递归平铺 dir2dirs 组内的嵌套 table,把任意深度的 table 元素展开为
--- 扁平的字符串条目列表(叶子按 ipairs 顺序保留,跳过非字符串与空串)。
--- @param group table
--- @return string[]
local function flatten_group(group)
  local out = {}
  local function walk(node)
    if type(node) == "table" then
      for _, v in ipairs(node) do
        walk(v)
      end
    elseif type(node) == "string" and node ~= "" then
      out[#out + 1] = node
    end
  end
  walk(group)
  return out
end

--- Build the list of camera HAL search directories for the current file.
--- The file path is used to locate the enclosing .repo root, then the file's
--- path relative to that root is prefix-matched against every entry in each
--- group of dir2dirs. Every group with at least one matching entry contributes
--- its whole directory list; the result is deduplicated.
--- @param filepath string current file path
--- @return string[] dirs list of absolute paths (existing only, deduplicated)
function M.camera_dirs(filepath)
  local repo = vim.fs.root(filepath, ".repo")
  if not repo then
    return {}
  end

  local rel = filepath:sub(#repo + 2):gsub("\\", "/") -- path relative to repo root
  if rel == "" then
    return {}
  end

  local HISIODM_HAL = vim.g.odm_hal_repositories
  local dir2dirs = {
    { CAMHAL, UAPI, APKERNEL, ISP, HISIODM_HAL },
    { CAMHAL, IPS },
    { UAPI, APKERNEL, KERNEL, HWKERNEL },
    { CAMHAL, OHOS_CAMERA_FWK, AOSP_CAMERA_FWK },
    { OHOS_CAMERA_FWK, AOSP_CAMERA_FWK, HELPSFWK, HWJS },
  }

  local dirs = {}
  local seen = {}
  local function add(sub)
    local path = repo .. "/" .. sub
    if not seen[path] and vim.fn.isdirectory(path) == 1 then
      seen[path] = true
      table.insert(dirs, path)
    end
  end

  for _, group in ipairs(dir2dirs) do
    local flat = flatten_group(group)
    local hit = false
    for _, prefix in ipairs(flat) do
      if is_under(rel, prefix) then
        hit = true
        break
      end
    end
    if hit then
      for _, sub in ipairs(flat) do
        add(sub)
      end
    end
  end
  vim.notify("searching dirs: " .. table.concat(dirs, ","), vim.log.levels.WARN)
  return dirs
end

-- 寄存器列表(与 which-key 内置 registers 插件保持一致)
local REGISTERS = '*+"-:.%/#=_abcdefghijklmnopqrstuvwxyz0123456789'

local REGISTER_LABELS = {
  ['"'] = "last deleted, changed, or yanked content",
  ["0"] = "last yank",
  ["-"] = "deleted or changed content smaller than one line",
  ["."] = "last inserted text",
  ["%"] = "name of the current file",
  [":"] = "most recent executed command",
  ["#"] = "alternate buffer",
  ["="] = "result of an expression",
  ["+"] = "synchronized with the system clipboard",
  ["*"] = "synchronized with the selection clipboard",
  ["_"] = "black hole",
  ["/"] = "last search pattern",
}

--- 清洗检索串:仅对寄存器 / (上次搜索) 把 K 写入的 \< \> 单词边界改成正则的边界 \b \b,
--- 以便把原始文本交给 rg 作为正则使用。
local function clean_search(key, value)
  if key == "/" then
    value = value:gsub("^\\<", "\\b"):gsub("\\>$", "\\b")
  end
  return value
end

--- which-key 的 <leader>/ spec:每个非空寄存器一条,选中后以该寄存器内容
--- 在当前 git 仓内 grep。
--- @return wk.Spec
function M.register_search_spec()
  local items = {}
  for i = 1, #REGISTERS do
    local key = REGISTERS:sub(i, i)
    local ok, value = pcall(vim.fn.getreg, key, 1)
    value = ok and type(value) == "string" and value or ""
    if value ~= "" then
      local preview = vim.fn.keytrans(vim.split(value, "\n")[1] or value)
      if #preview > 60 then
        preview = preview:sub(1, 60) .. "…"
      end
      local label = REGISTER_LABELS[key]
      items[#items + 1] = {
        key,
        function()
          local search = clean_search(key, value)
          if search ~= "" then
            local cwd = require("config.util").find_root({ ".git" })
            vim.schedule(function()
              Snacks.picker.grep({ search = search, cwd = cwd })
            end)
          end
        end,
        desc = (label and (label .. ": ") or "") .. preview,
      }
    end
  end
  return items
end

--- Patches the snacks picker matcher (once) so that, while a matcher's
--- `filename_only` flag is set, fuzzy matching targets the item's file
--- **basename** while the list keeps rendering the full path. The basename is
--- exposed to the match as the `file` field (`mods.field = "file"`) of a small
--- pseudo-item that still carries the real `item.file`, so the match runs on
--- the basename without ever touching the item itself. The basename hits are
--- shifted back onto the path's basename segment by `positions()`.
local filename_only_installed = false
local function install_filename_only()
  if filename_only_installed then
    return
  end
  filename_only_installed = true

  local matcher = require("snacks.picker.core.matcher")
  local match, positions = matcher._match, matcher.positions

  --- basename of `path` (falling back to `item.file` when `path` is empty).
  --- @param item snacks.picker.Item
  --- @param path string
  --- @return string
  local function basename_of(item, path)
    path = (path ~= "" and path) or item.file or ""
    return vim.fn.fnamemodify(path, ":t")
  end

  function matcher:_match(item, mods)
    -- Explicit `field:` / `file:line` patterns and regex mode keep their target.
    if self.filename_only and item.file and not mods.regex and not mods.field then
      -- Match against a pseudo item whose `file` (the field the match targets)
      -- is the basename; the real item — and thus the rendered full path — is
      -- left untouched. The basename is a suffix of `path`, so `positions()`
      -- shifts the hits onto it. All four return values are kept: `positions()`
      -- feeds the last one (str) into `fuzzy_positions`.
      local base = basename_of(item, (Snacks.picker.util.path(item) or item.file):gsub("\\", "/"))
      local pseudo = setmetatable({ idx = item.idx, score = 0, file = base }, { __index = item })
      return match(self, pseudo, setmetatable({ field = "file" }, { __index = mods }))
    end
    return match(self, item, mods)
  end

  function matcher:positions(item)
    local ret = positions(self, item)
    -- `_match` matched the basename, so the hits come back in basename
    -- coordinates, while the highlight pass locates them inside `item.text` —
    -- the *rendered* line (icon/prefix + full path). Find where the basename
    -- sits in that line and shift the hits there.
    if self.filename_only and type(ret.text) == "table" then
      local base = basename_of(item, (Snacks.picker.util.path(item) or item.file or ""):gsub("\\", "/"))
      if base ~= "" then
        local start = (item.text ~= "" and item.text or item.file or ""):find(base, 1, true)
        if start then
          start = start - 1
          for i, pos in ipairs(ret.text) do
            ret.text[i] = pos + start
          end
        end
      end
    end
    return ret
  end
end

--- snacks action: toggle "match file name only" on the current picker.
--- While enabled, fuzzy matching targets the basename while the list keeps
--- showing the full path; `<C-f>` is bound to this by lua/plugins/snacks.lua.
--- @param picker snacks.Picker
function M.toggle_filename_only(picker)
  install_filename_only()
  local on = not picker.matcher.filename_only
  picker.matcher.filename_only = on
  -- `list` builds its own matcher for highlight positions; keep it in sync so
  -- basename hits get highlighted.
  picker.list.matcher.filename_only = on
  picker.opts.filename_only = on -- drives the `{flags}` title indicator
  -- keep rendering the full path even while matching only the basename
  picker.opts.formatters.file.filename_only = false
  picker.list:set_target()
  picker:find()
end

function M.pick_async_tasks()
  -- 1. 调用 Vimscript 函数获取任务列表
  local tasks = vim.fn["asynctasks#list"]("")

  -- 2. 把 Vimscript 列表转换成 picker items
  local items = {}
  for _, task in ipairs(tasks) do
    table.insert(items, {
      -- text 字段是 picker 用来显示和搜索的内容
      text = task.name .. " | " .. task.command,
      -- 把 task 对象本身存起来，方便后续使用
      task = task,
    })
  end

  -- 3. 创建 picker
  Snacks.picker({
    title = "AsyncTasks",
    items = items,
    format = function(item)
      -- 自定义显示格式：任务名 + 命令
      return {
        { item.task.name, "DiagnosticInfo" },
        { " | ", "Comment" },
        { item.task.command, "Normal" },
      }
    end,
    confirm = function(picker, item)
      picker:close()
      -- 选中后执行对应的任务
      vim.cmd("AsyncTask " .. item.task.name)
    end,
  })
end

return M
