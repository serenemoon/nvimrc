-- <leader>/ :用 which-key 弹出寄存器列表(取代 LazyVim 默认的 grep-root)。
-- 选择某个寄存器后,以该寄存器内容作为检索串在当前 git 仓里 grep。
-- 其中 / 寄存器(上次搜索)会先去掉 K 写入的 \< \> 单词边界再用作正则。
-- 内容由 snacks_custom.register_search_spec() 在按下 <leader>/ 时实时生成。
return {
  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        {
          "<leader>/",
          group = "Registers",
          expand = function()
            return require("snacks_custom").register_search_spec()
          end,
        },
      },
    },
  },
}
