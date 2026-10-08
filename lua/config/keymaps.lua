-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
--
--
-- 禁用 LazyVim 默认快捷键
-- 这些是 lazyvim.config.keymaps 里用 map() 直接注册的核心键(以及 bufferline 的
-- <S-h>/<S-l>),不属于 lazy.nvim 的懒加载 keys,无法用 { lhs, false } 的 spec 写法
-- 禁用,只能用 vim.keymap.del 删除。用 pcall 兜底,避免键未定义时抛 E31。
for _, key in ipairs({ "<C-h>", "<C-j>", "<C-k>", "<C-l>", "L", "H" }) do
  pcall(vim.keymap.del, "n", key)
end

-- 自定义快捷键

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

-- run file
vim.keymap.set("n", "<F5>", function()
  vim.cmd([[:AsyncTask file-run]])
end, { desc = "async run file" })

-- build file
vim.keymap.set("n", "<F9>", function()
  vim.cmd([[:AsyncTask file-build]])
end, { desc = "async build file" })

-- lsp infos
vim.keymap.set("n", "<F10>", function()
  vim.cmd([[:checkhealth vim.lsp]])
end, { desc = "check health vimlsp" })
vim.keymap.set("n", "<F22>", function()
  vim.cmd([[:tabnew ~/.local/state/nvim/lsp.log]])
end, { desc = "check health vimlsp" })

-- copy symbol/selection into the search register /
local function yank_to_search_register()
  local mode = vim.fn.mode()
  local is_visual = mode == "v" or mode == "V" or mode == "\22"
  local text
  if is_visual then
    -- visual 模式：取选中的字符串（先规范起点/终点顺序）。
    -- 注意：在 x 模式映射里 visualmode() 可能是空的（本会话尚未用过 visual 时会这样，
    -- 用它会触发 E475 导致映射中断），因此直接用 mode() 作为选区类型。
    local s = vim.fn.getpos("v")
    local e = vim.fn.getpos(".")
    if s[2] > e[2] or (s[2] == e[2] and s[3] > e[3]) then
      s, e = e, s
    end
    text = table.concat(vim.fn.getregion(s, e, { type = mode }), "\n")
  else
    -- normal 模式：取光标下的 symbol
    text = vim.fn.expand("<cword>")
  end
  if text == "" then
    vim.notify("没有可复制的符号", vim.log.levels.WARN)
  else
    local escaped = vim.fn.escape(text, [[\/.*[]~^$]])
    -- normal 模式按单词边界搜索(\<...\>);visual 模式按选中文本原样搜索(非边界)
    if not is_visual then
      escaped = [[\<]] .. escaped .. [[\>]]
    end
    vim.fn.setreg("/", escaped)
    vim.notify("已复制到 /: " .. escaped, vim.log.levels.INFO)
    vim.cmd([[set hls]])
  end
  -- visual 模式下复制完成后退出 visual 模式
  if is_visual then
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
  end
end

-- K：复制光标下符号/选区到搜索寄存器 /
-- <C-k>：LSP hover
vim.keymap.set(
  { "n", "x" },
  "K",
  yank_to_search_register,
  { desc = "复制光标下符号/选区到搜索寄存器 /" }
)
vim.keymap.set("n", "<C-k>", function()
  vim.lsp.buf.hover()
end, { desc = "LSP Hover" })

-- Neovim 核心在 LSP attach 时,若此刻全局 K 为空,会为 buffer 设置 buffer-local 的
-- K = hover(runtime/lua/vim/lsp.lua);LazyVim 也会为 LSP buffer 设 K。本文件按
-- LazyVim 的约定在 VeryLazy 才加载,晚于 LSP attach,故全局 K 盖不住核心的
-- buffer-local 映射。这里在 LspAttach 时把 buffer-local K 重新指回本函数。
-- (LazyVim 侧的同名 K 已在 lua/plugins/self.lua 里用 { "K", false } 关闭。)
local function map_search_register(buf)
  vim.keymap.set({ "n", "x" }, "K", yank_to_search_register, {
    buffer = buf,
    desc = "复制光标下符号/选区到搜索寄存器 /",
  })
end

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("SearchRegisterKey", { clear = true }),
  callback = function(args)
    map_search_register(args.buf)
  end,
})

-- 本文件加载时可能已有 buffer 完成 LSP attach(如 `nvim file.c`),补设一次。
for _, buf in ipairs(vim.api.nvim_list_bufs()) do
  if vim.api.nvim_buf_is_loaded(buf) and #vim.lsp.get_clients({ bufnr = buf }) > 0 then
    map_search_register(buf)
  end
end
