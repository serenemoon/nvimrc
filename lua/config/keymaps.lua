-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
--

local function reload_current_script()
  local path = vim.fn.expand("%:p")
  if path == "" then
    vim.notify("当前缓冲区没有文件名", vim.log.levels.WARN)
    return
  end

  if path:match("%.lua$") then
    -- 推断模块名：.../lua/plugins/foo.lua -> plugins.foo
    local mod = path:match("lua/(.+)%.lua$")
    if mod then
      mod = mod:gsub("/", ".")
      package.loaded[mod] = nil -- 清缓存
      local ok, err = pcall(require, mod) -- 重新加载
      vim.notify(
        ok and ("已重新加载 " .. mod) or ("加载失败: " .. err),
        ok and vim.log.levels.INFO or vim.log.levels.ERROR
      )
      return
    end
    vim.cmd("luafile " .. vim.fn.fnameescape(path)) -- 不在 lua/ 下（如 init.lua）直接执行
  else
    vim.cmd("source " .. vim.fn.fnameescape(path)) -- Vimscript
  end
end

-- open / edit script dirs
vim.keymap.set("n", ",ss", reload_current_script, { desc = "重新加载当前脚本" })
vim.keymap.set("n", ",ee", ":e " .. vim.fn.stdpath("config") .. "<CR>", {})

-- move across windows including terminal
vim.keymap.set({ "n", "v" }, "<A-h>", "<C-W><C-H>", {})
vim.keymap.set({ "n", "v" }, "<A-j>", "<C-W><C-J>", {})
vim.keymap.set({ "n", "v" }, "<A-k>", "<C-W><C-K>", {})
vim.keymap.set({ "n", "v" }, "<A-l>", "<C-W><C-L>", {})
vim.keymap.set({ "t" }, "<A-h>", "<C-\\><C-n><C-W><C-H>", {})
vim.keymap.set({ "t" }, "<A-j>", "<C-\\><C-n><C-W><C-J>", {})
vim.keymap.set({ "t" }, "<A-k>", "<C-\\><C-n><C-W><C-K>", {})
vim.keymap.set({ "t" }, "<A-l>", "<C-\\><C-n><C-W><C-L>", {})

-- quit/save vim
vim.keymap.set({ "n", "v", "i" }, "<A-w>", ":w<CR>", {})
vim.keymap.set({ "n", "v" }, "<A-q>", ":q<CR>", {})
vim.keymap.set({ "n", "v" }, "<A-Q>", ":qall<CR>", {})
vim.keymap.set({ "t" }, "<A-q>", "exit<CR>", {})

-- terminal
vim.keymap.set({ "n", "t" }, "<A-=>", "<C-_>", { remap = true })

-- markdown-preview
vim.keymap.set("n", "<A-M><A-M>", function()
  require("render-markdown").buf_toggle()
end, { desc = "Toggle buf markdown render" })
vim.keymap.set("n", "<A-m><A-m>", function()
  require("render-markdown").toggle()
end, { desc = "Toggle all markdown render" })

-- 禁用Lazyvim默认快捷键
vim.keymap.del({ "n" }, "<C-h>")
vim.keymap.del({ "n" }, "<C-j>")
vim.keymap.del({ "n" }, "<C-k>")
vim.keymap.del({ "n" }, "<C-l>")

vim.keymap.del({ "n" }, "L")
vim.keymap.del({ "n" }, "H")
