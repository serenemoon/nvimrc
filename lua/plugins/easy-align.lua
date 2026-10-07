return {
  {
    "junegunn/vim-easy-align",
    -- 使用 keys 实现懒加载，只有按下 ga 或 gA 时才会加载插件
    keys = {
      { "ga", "<Plug>(EasyAlign)", mode = { "n", "x" }, desc = "EasyAlign" },
    },
  },
}
