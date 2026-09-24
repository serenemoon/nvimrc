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
          local repo = require("snacks_custom").find_repo_root()
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
          local repo = require("snacks_custom").find_repo_root()
          if not repo then
            vim.notify("No .repo directory found", vim.log.levels.WARN)
            return
          end
          local dirs = require("snacks_custom").camera_dirs(repo)
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
          local repo = require("snacks_custom").find_repo_root()
          if not repo then
            vim.notify("No .repo directory found", vim.log.levels.WARN)
            return
          end
          local dirs = require("snacks_custom").camera_dirs(repo)
          Snacks.picker.grep({
            search = word,
            dirs = dirs,
            live = true,
            title = "Camera HAL Grep: " .. word,
          })
        end,
        desc = "Grep camera HAL dirs (word under cursor)",
        mode = { "n", "x" },
      },
      {
        ",fF",
        function()
          local repo = require("snacks_custom").find_repo_root()
          if not repo then
            vim.notify("No .repo directory found", vim.log.levels.WARN)
            return
          end
          local dirs = require("snacks_custom").camera_dirs(repo)
          Snacks.picker.files({ dirs = dirs })
        end,
        desc = "Find files in camera HAL dirs",
      },
      {
        "go",
        function()
          Snacks.picker.resume()
        end,
        desc = "Resume Recent Pickers",
      },
    },
  },
}
