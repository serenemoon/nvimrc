-- 用当前文件所在的 .repo 根目录作为 clangd 的 workspace root。
-- 用 root_dir 函数而非 root_markers,避免被 LazyVim clangd extra 的
-- root_markers 列表在合并时覆盖(lsp.start 中 root_dir 优先级更高)。
vim.lsp.config("clangd", {
  root_dir = function(bufnr, on_dir)
    on_dir(
      vim.fs.joinpath(vim.fs.root(bufnr, { ".repo" }), "out/generic_generic_arm_64only/hisi_nanchang_phone_standard")
    )
  end,
})

vim.lsp.enable("clangd")
