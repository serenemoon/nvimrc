-- <leader>R: search the word under the cursor in the current repo via Snacks picker

-- 在 snacks.explorer 里,于**同一目录**的节点间移动,不进入已展开目录的子节点。
-- 同级判定:相邻 item 的 parent 引用相同;顶层节点的 parent 为 nil,也归为一组。
-- 因此从当前项沿列表向 delta 方向找第一个 parent 相同的项即下一个同级节点,
-- 其间夹着的目录子项会被跳过。
local function move_sibling(picker, delta)
  local list = picker.list
  local cur = list.cursor
  local item = list:get(cur)
  if not item then
    return
  end
  local parent = item.parent
  local count = list:count()
  local idx = cur + delta
  while idx >= 1 and idx <= count do
    local other = list:get(idx)
    if other and other.parent == parent then
      list:view(idx)
      return
    end
    idx = idx + delta
  end
end

-- 直接跳到当前节点所在的**同级节点组**的边界:last=true 取组内最后一个
-- 同级节点,last=false 取第一个。同级判定与 move_sibling 相同(parent 引用
-- 相等);夹在组内的目录子项(其 parent 指向被展开的目录)不会被匹配。
local function move_sibling_edge(picker, last)
  local list = picker.list
  local item = list:get(list.cursor)
  if not item then
    return
  end
  local parent = item.parent
  local target
  for idx = 1, list:count() do
    local other = list:get(idx)
    if other and other.parent == parent then
      target = idx
      if not last then
        break
      end
    end
  end
  if target then
    list:view(target)
  end
end

-- 打开路径所在的目录：目录直接打开，文件则打开其父目录。
local function open_path_dir(path)
  path = vim.trim(path or "")
  if path == "" then
    vim.notify("No path found", vim.log.levels.WARN)
    return
  end

  local abs = vim.fn.fnamemodify(vim.fn.expand(path), ":p")
  local stat = vim.uv.fs_stat(abs)
  if not stat then
    vim.notify("Path not found: " .. path, vim.log.levels.WARN)
    return
  end
  if stat.type ~= "directory" then
    abs = vim.fn.fnamemodify(abs, ":p:h")
  end
  require("snacks_custom").open_focus_close(abs)
end

local function open_path_at_cursor()
  local mode = vim.fn.mode()
  if mode == "v" or mode == "V" or mode == "\22" then
    local lines = vim.fn.getregion(vim.fn.getpos("v"), vim.fn.getpos("."), { type = mode })
    open_path_dir(table.concat(lines, "\n"))
    return
  end

  -- normal: 光标下的文件所在目录；没有 <cfile> 时回退到当前文件目录
  local cfile = vim.fn.expand("<cfile>")
  local dir = cfile ~= "" and vim.fn.expand("<cfile>:p:h") or vim.fn.expand("%:p:h")
  open_path_dir(dir)
end

return {
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        layout = {
          preview = false,
        },
        toggles = {
          -- {flags} 标题指示器:文件名匹配开启时显示该标记
          filename_only = { icon = "F", value = true },
        },
        actions = {
          explorer_sibling_next = function(picker)
            move_sibling(picker, 1)
          end,
          explorer_sibling_prev = function(picker)
            move_sibling(picker, -1)
          end,
          -- 跳到当前同级节点组的最后一个/第一个节点
          explorer_sibling_last = function(picker)
            move_sibling_edge(picker, true)
          end,
          explorer_sibling_first = function(picker)
            move_sibling_edge(picker, false)
          end,
          --- <C-f>:仅在文件名(而非整个路径)上做 fuzzy 匹配;再按一次恢复。
          --- 动作名刻意不叫 `toggle_filename_only`——那正是 toggles 自动生成的
          --- 通用动作名,会被其覆盖,从而丢失 matcher 补丁与显示切换。
          filename_only = function(picker)
            require("snacks_custom").toggle_filename_only(picker)
          end,
        },
        win = {
          input = {
            keys = {
              ["<C-f>"] = { "filename_only", mode = { "i", "n" } },
              ["<Esc>"] = { "close", mode = { "n", "i" } },
            },
          },
        },
        sources = {
          explorer = {
            win = {
              list = {
                keys = {
                  ["|"] = "edit_vsplit",
                  ["-"] = "edit_split",
                  ["u"] = "explorer_up",
                  ["o"] = "confirm",
                  ["<c-r>"] = "explorer_update",
                  -- 同一目录内上/下移动,跳过已展开目录的子节点
                  ["<C-j>"] = { "explorer_sibling_next", mode = { "n" } },
                  ["<C-k>"] = { "explorer_sibling_prev", mode = { "n" } },
                  -- 直接跳到同一目录内的最后一个/第一个同级节点
                  ["J"] = { "explorer_sibling_last", mode = { "n" } },
                  ["K"] = { "explorer_sibling_first", mode = { "n" } },
                },
              },
            },
          },
        },
      },
    },
    keys = {
      { "<leader><space>", false, desc = "禁用 Find Files" },
      -- 让 <leader>/ 交给 which-key 的寄存器组(见下方 which-key spec)
      { "<leader>/", false, desc = "禁用 Grep (Root Dir)" },
      { "<leader>E", false, desc = "禁用 explorer CWD" },
      { "<leader>e", false, desc = "禁用 explorer root" },
      {
        "<M-t>",
        function()
          require("snacks_custom").pick_async_tasks()
        end,
        desc = "禁用 Find Files",
      },
      {
        "<leader>R",
        function()
          local word = vim.fn.expand("<cword>")
          if word == "" then
            vim.notify("No word under cursor", vim.log.levels.WARN)
            return
          end

          -- resolve the git repo root of the current file
          local cwd = require("config.util").find_root({ ".git" })
          Snacks.picker.grep({ search = word, cwd = cwd })
        end,
        desc = "Search word under cursor (root grep)",
        mode = { "n", "x" },
      },
      {
        "<leader>r",
        function()
          -- resolve the git repo root of the current file
          local cwd = require("config.util").find_root({ ".git" })
          Snacks.picker.grep({ cwd = cwd, live = true })
        end,
        desc = "Search word (repo grep)",
        mode = { "n", "x" },
      },
      {
        "<leader>l",
        function()
          Snacks.picker.lines()
        end,
        desc = "Grep buffer lines",
        mode = { "n", "x" },
      },
      {
        "<leader><leader>l",
        function()
          vim.cmd("Lazy")
        end,
        desc = "Lazy",
      },
      {
        "<leader>L",
        function()
          local word = vim.fn.expand("<cword>")
          if word == "" then
            vim.notify("No word under cursor", vim.log.levels.WARN)
            return
          end
          Snacks.picker.lines({
            pattern = word,
            search = "",
            title = "Buffer Lines: ",
          })
          vim.defer_fn(vim.cmd.stopinsert, 50)
        end,
        desc = "Search word under cursor (current buffer)",
        mode = { "n", "x" },
      },
      {
        "<leader>m",
        function()
          Snacks.picker.recent()
        end,
        desc = "Recent files",
      },
      {
        "<leader><leader>m",
        function()
          Snacks.picker.recent({ filter = { paths = { [vim.fn.stdpath("data")] = true } } })
        end,
        desc = "Recent Files With Vim Data",
      },
      {
        "<leader>M",
        function()
          local repo = require("config.util").find_root({ ".repo", ".git", dfs = true })
          if not repo then
            vim.notify("No .repo/.git directory found", vim.log.levels.WARN)
            return
          end
          Snacks.picker.recent({
            filter = { cwd = repo },
            title = "Recent files in repo/git",
          })
        end,
        desc = "Recent files (repo only)",
      },
      {
        "<leader><leader>r",
        function()
          local repo = vim.fs.root(0, ".repo")
          if not repo then
            vim.notify("No .repo directory found", vim.log.levels.WARN)
            return
          end
          local dirs = require("snacks_custom").camera_dirs(vim.api.nvim_buf_get_name(0))
          Snacks.picker.grep({
            dirs = dirs,
            live = true,
            title = "Camera HAL Grep (live)",
          })
        end,
        desc = "Grep camera HAL dirs (live)",
      },
      {
        "<leader><leader>R",
        function()
          local word = vim.fn.expand("<cword>")
          if word == "" then
            vim.notify("No word under cursor", vim.log.levels.WARN)
            return
          end
          local repo = vim.fs.root(0, ".repo")
          if not repo then
            vim.notify("No .repo directory found", vim.log.levels.WARN)
            return
          end
          local dirs = require("snacks_custom").camera_dirs(vim.api.nvim_buf_get_name(0))
          Snacks.picker.grep({
            search = word,
            dirs = dirs,
            live = true,
            title = "Camera HAL Grep: " .. word,
          })
          vim.defer_fn(vim.cmd.stopinsert, 50)
        end,
        desc = "Grep camera HAL dirs (word under cursor)",
        mode = { "n", "x" },
      },
      {
        "gF",
        function()
          local repo = vim.fs.root(0, ".repo")
          if not repo then
            vim.notify("No .repo directory found", vim.log.levels.WARN)
            return
          end
          local name = vim.fn.fnamemodify(vim.fn.expand("<cfile>"), ":t")
          if name == "" then
            vim.notify("No file name under cursor", vim.log.levels.WARN)
            return
          end
          Snacks.picker.files({
            search = name,
            dirs = require("snacks_custom").camera_dirs(vim.api.nvim_buf_get_name(0)),
            live = true,
            title = "Camera HAL Find (filename): " .. name,
          })
        end,
        desc = "Find cfile name in camera HAL dirs",
        mode = { "n", "x" },
      },
      {
        ",fF",
        function()
          local dir = require("config.util").find_root({ ".git" })
          local dirs = require("snacks_custom").camera_dirs(dir)
          Snacks.picker.files({ dirs = dirs })
        end,
        desc = "Find files in camera HAL dirs",
      },
      {
        ",ff",
        function()
          local dir = require("config.util").find_root({ ".git" })
          Snacks.picker.files({ dirs = { dir } })
        end,
        desc = "Find files in git dir",
      },
      {
        "<M-r>",
        function()
          require("snacks_custom").pick_git_repos()
        end,
        desc = "Open git dir in repo (explorer, cached)",
      },
      {
        "<M-R>",
        function()
          require("snacks_custom").pick_git_repos(true)
        end,
        desc = "Open git dir in repo (explorer, refresh)",
      },
      {
        "<leader>fP",
        function()
          local lazydir = vim.fs.joinpath(vim.fn.stdpath("data"), "lazy")
          if not lazydir then
            vim.notify("No lazy directory found")
            return
          end
          Snacks.picker.files({ dirs = { lazydir }, title = "Plugin Files" })
        end,
        desc = "Find Plugin Files",
      },
      {
        "go",
        function()
          Snacks.picker.resume()
          vim.defer_fn(vim.cmd.stopinsert, 50)
        end,
        desc = "Resume Recent Pickers",
      },
      {
        "<F3>", -- 打开当前文件所在目录
        function()
          require("snacks_custom").open_focus_close(vim.fn.expand("%:p:h"))
        end,
        desc = "Open Cur File Directory",
      },
      {
        "<F15>", -- Shift+F3 打开当前文件所在项目根目录
        function()
          require("snacks_custom").open_focus_close(vim.fs.root(0, ".git"))
        end,
        desc = "Open Git Root Directory",
      },
      {
        "<F4>", -- 打开所在repo根目录
        function()
          require("snacks_custom").open_focus_close(vim.fs.root(0, ".repo"))
        end,
        desc = "Open Repo Root Directory",
      },
      {
        "<F16>", -- Shift+F4 打开用户目录
        function()
          require("snacks_custom").open_focus_close("~")
        end,
        desc = "Open User Home Directory",
      },
      {
        "<leader>ee",
        function()
          require("snacks_custom").open_focus_close(LazyVim.root())
        end,
        desc = "打开项目 root dir",
        mode = { "n", "x" },
      },
      {
        "<leader>eE",
        open_path_at_cursor,
        desc = "打开光标下路径 / 选中路径",
        mode = { "n", "x" },
      },
      {
        "<leader>ec", -- 打开 stdpath("config")
        function()
          require("snacks_custom").open_focus_close(vim.fn.stdpath("config"))
        end,
        desc = "Open Vim Config Directory",
      },
      {
        "<leader>ed", -- 打开 stdpath("data")
        function()
          require("snacks_custom").open_focus_close(vim.fn.stdpath("data"))
        end,
        desc = "Open Vim Data Directory",
      },
    },
  },
}
