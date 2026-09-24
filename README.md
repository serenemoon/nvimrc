# Neovim Config (LazyVim)

基于 [LazyVim](https://lazyvim.org) 的 Neovim 配置，针对 C/C++ 嵌入式开发（Android Camera HAL）做了定制。

## 环境要求

- Neovim >= 0.10
- [ripgrep](https://github.com/BurntSushi/ripgrep) (grep 搜索)
- [fd](https://github.com/sharkdp/fd) (文件查找)
- Git, Node.js (treesitter 编译)
- Python 3 (LeaderF)

## 目录结构

```
├── init.lua                  # 入口
├── lua/
│   ├── config/
│   │   ├── options.lua       # 选项 (leader=space, 禁用 mouse, 关闭 diagnostic 等)
│   │   ├── keymaps.lua       # 自定义快捷键
│   │   ├── lazy.lua          # lazy.nvim 配置 & extras 导入
│   │   ├── autocmds.lua      # 自动命令
│   │   └── commands.lua      # :Lua 用户命令
│   ├── plugins/
│   │   ├── self.lua          # 插件配置 (gruvbox, treesitter, lsp, mason, LeaderF 等)
│   │   ├── snacks.lua        # Snacks picker 快捷键
│   │   ├── blink.lua         # blink.cmp 补全
│   │   ├── render-markdown.lua
│   │   └── disable-keymaps.lua
│   └── snacks_custom.lua     # .repo 根目录查找 & camera HAL 目录辅助函数
├── lazyvim.json              # LazyVim extras (clangd, markdown, toml, gitui)
├── stylua.toml
└── LICENSE
```

## 启用的 LazyVim Extras

- `lazyvim.plugins.extras.lang.clangd` — C/C++ LSP
- `lazyvim.plugins.extras.lang.markdown` — Markdown
- `lazyvim.plugins.extras.lang.toml` — TOML
- `lazyvim.plugins.extras.lang.json` — JSON
- `lazyvim.plugins.extras.util.gitui` — Git UI
- `lazyvim.plugins.extras.ui.mini-starter` — 启动页

## 主要插件

| 插件 | 用途 |
|------|------|
| gruvbox.nvim | 配色方案 |
| blink.cmp | 补全引擎 |
| snacks.nvim | Picker / 搜索 / UI |
| nvim-treesitter | 语法高亮 |
| nvim-lspconfig | LSP (pyright, clangd) |
| LeaderF | 模糊查找 |
| mywords.nvim | 高亮光标下单词 |
| render-markdown.nvim | Markdown 渲染 |
| mason.nvim | 工具安装 (stylua, shfmt, shellcheck, flake8, gitui) |

## 快捷键

### 通用

| 快捷键 | 功能 |
|--------|------|
| `<space>R` | 在当前 git 仓库内 grep 光标下 symbol |
| `<space>L` | 在当前文件内搜索光标下 symbol |
| `<space>m` | 最近打开的文件 |
| `<space>M` | 最近打开的文件 (仅当前 .repo 仓库) |
| `<space><space>r` | 在 camera HAL 目录下 live grep |
| `<space><space>R` | 在 camera HAL 目录下 grep 光标下 symbol |
| `<space><space>f` | 查找 camera HAL 目录下的文件 |
| `,fF` | 同 `<space><space>f` |
| `mm` | 高亮/取消高亮光标下单词 |
| `mr` | 正则高亮 |
| `mn` | 清除所有高亮 |
| `,ss` | 重新加载当前 Lua 脚本 |
| `,ee` | 编辑 nvim 配置目录 |
| `<A-h/j/k/l>` | 窗口切换 (含终端) |
| `<A-w>` | 保存 |
| `<A-q>` | 退出 |
| `<A-M><A-M>` | 切换当前 buffer Markdown 渲染 |
| `<A-m><A-m>` | 全局切换 Markdown 渲染 |

### Picker 布局

所有 Snacks picker 使用 preview-on-top 布局：预览窗口在上，搜索框 + 列表在下。

## .repo 仓库支持

`lua/snacks_custom.lua` 提供两个辅助函数：

- `find_repo_root()` — 从当前文件向上查找 `.repo` 目录，返回仓库根路径
- `camera_dirs(repo)` — 返回 camera HAL 相关目录列表（自动过滤不存在的路径）

搜索的目录包括：

```
vendor/hisi/ap/hardware/camera_hal
vendor/hisi/ap/hardware/camera_product
vendor/hisi/ap/include/camera_hal
vendor/hisi/ap/kernel
device/hisi/customize
vendor/hisi/ap/bionic/libc/kernel/uapi
vendor/hisi/ap/platform
vendor/hisi/ffrt/basesrc
vendor/hisi/include/isp
vendor/hisi/isp
vendor/hisi/odm
vendor/huawei/chip_prod/DeviceDriverSubsystem/chip_prod_config_camera
vendor/huawei/chipset/modules/camera_x
vendor/huawei/foundation/multimedia/algorithm_camera
vendor/huawei/prebuilt/odm/hisi
```
