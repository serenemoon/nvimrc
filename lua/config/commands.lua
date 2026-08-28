-- 定义 :Lua 命令 - 将结果输出到新缓冲区
vim.api.nvim_create_user_command("Lua", function(opts)
  local code = opts.args
  if code == "" or code == nil then
    vim.notify("请输入要执行的 Lua 代码", vim.log.levels.WARN)
    return
  end

  -- 安全执行代码
  local ok, result = pcall(function()
    local fn, err = loadstring("return " .. code)
    if not fn then
      fn, err = loadstring(code)
      if not fn then
        error("代码编译失败: " .. err)
      end
      fn()
      return nil
    end
    return fn()
  end)

  if not ok then
    vim.notify("执行错误: " .. tostring(result), vim.log.levels.ERROR)
    return
  end

  -- 准备要输出的内容
  local output
  if result ~= nil then
    output = vim.inspect(result, { depth = 10, newline = "\n", indent = "  " })
  else
    output = "代码执行成功（无返回值）"
  end

  -- 创建一个新的不可编辑缓冲区并写入内容
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(output, "\n"))

  -- 使用 nvim_set_option_value 设置缓冲区选项（替代 nvim_buf_set_option）
  vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
  vim.api.nvim_set_option_value("readonly", true, { buf = buf })
  vim.api.nvim_set_option_value("filetype", "lua", { buf = buf })

  -- 创建一个新的窗口来显示这个缓冲区
  vim.cmd("new")
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, buf)

  -- 使用 nvim_set_option_value 设置窗口选项（替代 nvim_win_set_option）
  vim.api.nvim_set_option_value("wrap", false, { win = win })
  vim.api.nvim_set_option_value("number", false, { win = win })

  -- 设置缓冲区名称
  vim.api.nvim_buf_set_name(buf, "[Lua 执行结果]")

  -- 设置键盘映射，按 q 或 <Esc> 关闭窗口
  vim.api.nvim_buf_set_keymap(buf, "n", "q", ":bd!<CR>", { noremap = true, silent = true, desc = "关闭结果窗口" })
  vim.api.nvim_buf_set_keymap(
    buf,
    "n",
    "<Esc>",
    ":bd!<CR>",
    { noremap = true, silent = true, desc = "关闭结果窗口" }
  )
end, {
  nargs = "+",
  desc = "执行 Lua 代码并将结果输出到新缓冲区",
})
