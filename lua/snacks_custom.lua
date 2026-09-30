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

local CAMHAL = "vendor/hisi/ap/hardware/camera_hal"
local CAMINC = "vendor/hisi/ap/include/camera_hal"
local CAMPROD = "vendor/hisi/ap/hardware/camera_product"
local IPSHAL = "vendor/huawei/foundation/multimedia/algorithm_camera"
local IPSINC = "vendor/huawei/chipset/modules/camera_x"
local FFRT = "vendor/hisi/ffrt/basesrc"
local UAPI = "vendor/hisi/ap/bionic/libc/kernel/uapi"
local APKERNEL = "vendor/hisi/ap/kernel"
local ISPINC = "vendor/hisi/include/isp"
local ISPFW = "vendor/hisi/isp"
local HISIODM = "vendor/hisi/odm"
local HISIDTS = "device/hisi/customize"
local CAMINTF = "drivers/interface/camera"
local CAMFWK = "foundation/multimedia/camera_framework"
local IMGFWK = "foundation/multimedia/image_framework"
local IMGEFFECT = "foundation/multimedia/image_effect"
local HELPSFWK = "vendor/huawei/base/hiviewdfx/helps_fwk"
local HWJS = "vendor/huawei/interface/hmscore_sdk_js"

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

  local dir2dirs = {
    { CAMHAL, CAMINC, CAMPROD, UAPI, ISPINC, IPSHAL, IPSINC },
    { CAMHAL, CAMINC, CAMPROD, IPSHAL, IPSINC },
    { CAMHAL, CAMINC, CAMPROD, CAMINTF },
    { CAMFWK, IMGFWK, IMGEFFECT, CAMINTF, CAMHAL, CAMINC, CAMPROD },
    { CAMFWK, HELPSFWK, HWJS },
  }

  local dirs = {}
  local seen = {}
  for _, group in ipairs(dir2dirs) do
    local hit = false
    for _, prefix in ipairs(group) do
      if rel == prefix or rel:sub(1, #prefix + 1) == prefix .. "/" then
        hit = true
        break
      end
    end
    if hit then
      for _, sub in ipairs(group) do
        local path = repo .. "/" .. sub
        if not seen[path] and vim.fn.isdirectory(path) == 1 then
          seen[path] = true
          table.insert(dirs, path)
        end
      end
    end
  end
  return dirs
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
