-- <leader>R: search the word under the cursor in the current repo via Snacks picker
return {
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        layout = {
          preview = false,
        },
        sources = {
          explorer = {
            win = {
              list = {
                keys = {
                  ["|"] = "edit_vsplit",
                  ["-"] = "edit_split",
                },
              },
            },
          },
        },
      },
    },
    keys = {
      { "<leader><space>", false, desc = "禁用 Find Files" },
      {
        "<leader>R",
        function()
          local word = vim.fn.expand("<cword>")
          if word == "" then
            vim.notify("No word under cursor", vim.log.levels.WARN)
            return
          end
          -- resolve the git repo root of the current file
          local file = vim.api.nvim_buf_get_name(0)
          local dir = file ~= "" and vim.fn.fnamemodify(file, ":h") or vim.fn.getcwd()
          local root = vim.fs.find(".git", { upward = true, path = dir, type = "directory" })[1]
          local cwd = root and vim.fn.fnamemodify(root, ":h") or vim.fn.getcwd()
          Snacks.picker.grep({ search = word, cwd = cwd })
        end,
        desc = "Search word under cursor (root grep)",
        mode = { "n", "x" },
      },
      {
        "<leader>r",
        function()
          -- resolve the git repo root of the current file
          local file = vim.api.nvim_buf_get_name(0)
          local dir = file ~= "" and vim.fn.fnamemodify(file, ":h") or vim.fn.getcwd()
          local root = vim.fs.find(".git", { upward = true, path = dir, type = "directory" })[1]
          local cwd = root and vim.fn.fnamemodify(root, ":h") or vim.fn.getcwd()
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
        "<leader>M",
        function()
          local repo = vim.fs.root(0, ".repo")
          if not repo then
            vim.notify("No .repo directory found", vim.log.levels.WARN)
            return
          end
          Snacks.picker.recent({
            filter = { cwd = repo },
            title = "Recent files in repo",
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
        ",fF",
        function()
          local repo = vim.fs.root(0, ".repo")
          if not repo then
            vim.notify("No .repo directory found", vim.log.levels.WARN)
            return
          end
          local dirs = require("snacks_custom").camera_dirs(vim.api.nvim_buf_get_name(0))
          Snacks.picker.files({ dirs = dirs })
        end,
        desc = "Find files in camera HAL dirs",
      },
      {
        ",ff",
        function()
          local dir = vim.fs.root(0, ".git") or vim.fn.getcwd()
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
        desc = "Find files in plugins dirs",
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
    },
  },
}
