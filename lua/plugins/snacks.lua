-- preview-on-top layout: preview window on top, input + list on bottom
local preview_top_layout = {
  layout = {
    box = "vertical",
    backdrop = false,
    width = 0.8,
    min_width = 120,
    height = 0.8,
    border = true,
    title = "{title} {live} {flags}",
    title_pos = "center",
    { win = "preview", title = "{preview}", height = 0.4, border = "bottom" },
    {
      box = "vertical",
      { win = "input", height = 1, border = "top" },
      { win = "list", border = "none" },
    },
  },
}

-- <leader>R: search the word under the cursor in the current repo via Snacks picker
return {
  {
    "folke/snacks.nvim",
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
          Snacks.picker.grep({ search = word, cwd = cwd, layout = preview_top_layout })
        end,
        desc = "Search word under cursor (repo grep)",
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
            layout = preview_top_layout,
          })
        end,
        desc = "Search word under cursor (current buffer)",
        mode = { "n", "x" },
      },
      {
        "<leader>m",
        function()
          Snacks.picker.recent({ layout = preview_top_layout })
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
            layout = preview_top_layout,
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
            layout = preview_top_layout,
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
            layout = preview_top_layout,
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
          Snacks.picker.files({ dirs = dirs, layout = preview_top_layout })
        end,
        desc = "Find files in camera HAL dirs",
      },
    },
  },
}
