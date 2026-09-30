-- 本脚本所在目录作为 clang_root；当 clang_root/.repo 存在时，
-- 复用现有 clangd 的启动命令，并把可执行文件替换为仓内自带的 clangd。
--
-- 时机说明：LazyVim 的 nvim-lspconfig 以 BufReadPre/BufNewFile 懒加载，其 config
-- 会在加载时执行 vim.lsp.config("clangd", { cmd = { "clangd", ... } })。本脚本由
-- nvim-config-local 在 VimEnter 时 source，若此时立即改 cmd，会被随后加载的
-- lspconfig 覆盖（这正是“改完又被篡改”的原因）。
--
-- 因此按三步保证最终生效且保留原有命令行参数：
--   1. 立即套用一次：用于 lspconfig 已先加载、随后才 source 本脚本的情形（目录切换）。
--   2. BufReadPre/BufNewFile：本脚本(VimEnter)才注册、晚于 lazy.nvim 启动期注册，
--      故执行顺序为 lspconfig 设置 cmd="clangd" -> 本脚本替换可执行文件 -> FileType 启动客户端。
--   3. LspAttach：`nvim file.c` 时首个客户端可能已用上游 clangd 启动，此时停掉它，
--      让重新使能触发的 FileType 用仓内 clangd 重新拉起。

local function script_dir()
  local src = debug.getinfo(1, "S").source
  if src:sub(1, 1) == "@" then
    src = src:sub(2)
  end
  if vim.fn.filereadable(src) == 1 then
    return vim.fn.fnamemodify(src, ":p:h")
  end
  return vim.fn.getcwd()
end

local clang_root = script_dir()

-- 候选 clangd 可执行文件（相对仓根），按顺序取第一个存在的；都不存在则为 nil。
local CLANGD_CANDIDATES = {
  "prebuilts/clang/host/linux-x86/clang-r416183b/bin/clangd",
  "prebuilts/clang/ohos/linux-x86_64/llvm/bin/clangd",
}

local clangd_exe
for _, rel in ipairs(CLANGD_CANDIDATES) do
  local exe = vim.fs.joinpath(clang_root, rel)
  if vim.fn.executable(exe) == 1 then
    clangd_exe = exe
    break
  end
end

local function is_repo()
  return clangd_exe ~= nil
    and vim.fn.isdirectory(clang_root) == 1
    and vim.fn.isdirectory(vim.fs.joinpath(clang_root, ".repo")) == 1
end

-- 抽取现有 clangd cmd，仅替换第 1 个元素(可执行文件)，其余参数原样保留。
-- 返回是否发生了改变。
local function apply_clangd_cmd()
  if not is_repo() then
    return false
  end

  local cur = vim.lsp.config.clangd and vim.lsp.config.clangd.cmd
  if cur ~= nil and type(cur) ~= "table" then
    return false -- cmd 为函数等非表形式，不做替换
  end
  cur = cur or {}
  -- 只替换第 1 个元素(可执行文件)，其余参数原样保留；构造新表，避免与 cur 别名。
  local cmd = #cur == 0 and { clangd_exe } or vim.list_extend({ clangd_exe }, vim.list_slice(cur, 2))

  if vim.deep_equal(cmd, cur) then
    return false -- 已是目标命令，无需重复设置
  end

  vim.lsp.config("clangd", { cmd = cmd })
  return true
end

-- 若已有用非目标 clangd 启动的客户端(如 `nvim file.c`：文件在 VimEnter 之前就已
-- 读取并启动客户端)，停掉它并重新触发，使其用仓内 clangd 重新拉起。
local function restart_foreign_clangd()
  local stopped = false
  for _, client in ipairs(vim.lsp.get_clients({ name = "clangd" })) do
    local cl = client.config.cmd
    if type(cl) == "table" and cl[1] ~= clangd_exe then
      client:stop()
      stopped = true
    end
  end
  if stopped then
    -- 重新使能会重新触发 FileType，进而用修正后的 cmd 重启客户端。
    vim.lsp.enable("clangd")
  end
end

-- 立即尝试一次：覆盖“lspconfig 已加载后再 source 本脚本”的情形(如目录切换、
-- `nvim file.c`)。若刚才改动了 cmd 且已有旧客户端，则重启之。
if apply_clangd_cmd() then
  restart_foreign_clangd()
end

-- 关键：在 lspconfig 应用配置之后、clangd 客户端启动之前再次套用。
if is_repo() then
  vim.api.nvim_create_autocmd({ "BufReadPre", "BufNewFile" }, {
    group = vim.api.nvim_create_augroup("RepoClangdCmd", { clear = true }),
    callback = apply_clangd_cmd,
  })

  -- 兜底：`nvim file.c` 时首个客户端的启动早于本脚本，可能在 VimEnter 时仍处于
  -- 初始化中而不被 get_clients 看到，故在 attach 时再校正一次。
  vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("RepoClangdAttach", { clear = true }),
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      if client and client.name == "clangd" then
        apply_clangd_cmd()
        -- 延迟到主循环，避免在 autocmd 内触发 FileType 被嵌套抑制。
        vim.schedule(restart_foreign_clangd)
      end
    end,
  })
end
