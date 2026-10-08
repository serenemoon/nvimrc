# Neovim Config (LazyVim)

基于 [LazyVim](https://lazyvim.org) 的 Neovim 配置，针对 C/C++ 嵌入式开发（Android Camera HAL）做了定制。

## 环境要求

- Neovim >= 0.10
- [ripgrep](https://github.com/BurntSushi/ripgrep) (grep 搜索)
- [fd](https://github.com/sharkdp/fd) (文件查找)
- Git, Node.js (treesitter 编译)
- Python 3 (LeaderF)
- (可选) `repo` — 用于 `<M-r>`/`<M-R>` 快速列出 `.repo` 下的 git 仓库

## 安装

运行仓库根目录的 `setup` 脚本：

```
./setup
```

- 把 `~/.config/nvim` 软链到本仓库；
- 若系统没有 `tree-sitter`，则把仓库内 `external/tree-sitter` 软链到 `~/bin/tree-sitter`。

## 目录结构

```
├── init.lua                  # 入口 (config-local -> lazy -> commands)
├── setup                     # 安装脚本: 链接 ~/.config/nvim 与 tree-sitter
├── async_tasks.ini           # asynctasks.vim 的任务定义 (file-run / file-build)
├── lazyvim.json              # LazyVim extras 声明
├── lua/
│   ├── config/
│   │   ├── options.lua       # 选项 (leader=space, 关闭 mouse/diagnostic 等)
│   │   ├── keymaps.lua       # 自定义快捷键 (窗口/终端/运行/搜索寄存器)
│   │   ├── lazy.lua          # lazy.nvim 配置 & extras 导入
│   │   ├── autocmds.lua      # 自动命令
│   │   ├── commands.lua      # :LspLog / :Lua 用户命令
│   │   └── config-local.lua  # 进入 .repo 时自动生成 .nvim.lua
│   ├── plugins/
│   │   ├── self.lua          # 主插件配置 (gruvbox, treesitter, lsp, mason 等)
│   │   ├── snacks.lua        # Snacks picker 快捷键 & explorer 同级导航
│   │   ├── blink.lua         # blink.cmp 补全
│   │   ├── side-kick.lua     # sidekick.nvim (CLI 集成)
│   │   ├── vim-mark.lua      # 单词/正则高亮 (m 系列键)
│   │   ├── easy-align.lua    # vim-easy-align (ga)
│   │   ├── mini.align.lua    # mini.align (默认键位已禁用)
│   │   ├── vim-fugitive.lua  # Git 集成
│   │   ├── render-markdown.lua
│   │   ├── config-local.lua  # nvim-config-local
│   │   └── tree-sitter.lua   # (空 spec, 占位)
│   └── snacks_custom.lua     # .repo / camera HAL 目录 & 异步任务辅助函数
├── config-local/             # config-local 的 .nvim.lua 模板 (不随仓库分发)
│   ├── .repo.nvim.lua        # 仓内 clangd 替换逻辑
│   └── .proto.nvim.lua
├── stylua.toml
└── LICENSE
```

## 启用的 LazyVim Extras

来自 `lazyvim.json`：

- `lazyvim.plugins.extras.coding.yanky` — yank 高亮
- `lazyvim.plugins.extras.editor.dial` — 增减数字/日期
- `lazyvim.plugins.extras.lang.clangd` — C/C++ LSP
- `lazyvim.plugins.extras.lang.markdown` — Markdown
- `lazyvim.plugins.extras.lang.toml` — TOML
- `lazyvim.plugins.extras.util.gitui` — Git UI

此外 `config/lazy.lua` 额外导入 `lazyvim.plugins.extras.lang.json`。

## 主要插件

| 插件 | 用途 |
|------|------|
| gruvbox.nvim | 配色方案 |
| blink.cmp | 补全引擎 |
| snacks.nvim | Picker / 搜索 / UI |
| nvim-treesitter | 语法高亮 |
| nvim-lspconfig | LSP (pyright, clangd) |
| vim-mark | 单词 / 正则多色高亮 |
| sidekick.nvim | CLI (AI/终端) 集成 |
| vim-easy-align | 对齐 (`ga`) |
| mini.align | 对齐 (默认键位已关闭) |
| mini.surround | 包围操作 (`gsa` 等) |
| vim-fugitive | Git 命令集成 |
| asynctasks.vim / asyncrun.vim | 异步运行 / 构建 |
| nvim-config-local | 按工程加载 `.nvim.lua` |
| render-markdown.nvim | Markdown 渲染 |
| LeaderF | 模糊查找 |
| mason.nvim | 工具安装 (stylua, shfmt, shellcheck, flake8, gitui) |

## 快捷键

`<leader>` 为空格，`<localleader>` 为 `\`。

### 通用 / 编辑

| 快捷键 | 模式 | 功能 |
|--------|------|------|
| `<A-h/j/k/l>` | n/v/t | 窗口切换 (含终端) |
| `<A-w>` | n/v/i | 保存 |
| `<A-q>` | n/v/t | 退出 |
| `<A-Q>` | n/v | `:qall` |
| `<A-=>` | n/t | 终端内发送 `C-_` |
| `<F5>` | n | 异步运行当前文件 (`file-run`) |
| `<F9>` | n | 异步构建当前文件 (`file-build`) |
| `<F10>` | n | `:checkhealth vim.lsp` |
| `<F22>` (S-F10) | n | 打开 LSP 日志文件 |
| `,ss` | n | 重新加载当前 Lua/Vimscript 脚本 |
| `,ee` | n | 编辑 nvim 配置目录 |

### 搜索 / 高亮

| 快捷键 | 模式 | 功能 |
|--------|------|------|
| `K` | n/x | 复制光标下 symbol / 选区到搜索寄存器 `/`（normal 按单词边界 `\<...\>`，visual 按原文） |
| `<C-k>` | n | LSP hover |
| `mm` | n/v | 高亮 / 取消高亮光标下单词 |
| `mr` | n/v | 正则高亮 |
| `mn` | n | 切换全部高亮 |
| `mN` | n | 清除全部高亮 |
| `m*` / `m#` | n | 跳转到下一个 / 上一个当前高亮词 |
| `m/` / `m?` | n | 跳转到下一个 / 上一个任意高亮词 |
| `ga` | n/x | vim-easy-align 对齐 |
| `gsa` / `gsd` / `gsr` / `gsf` / `gsF` / `gsh` / `gsn` | n/x | mini.surround 包围操作 |

### Snacks Picker

| 快捷键 | 功能 |
|--------|------|
| `<leader>R` | 在当前 git 仓库内 grep 光标下 symbol |
| `<leader>r` | 在当前 git 仓库内 live grep |
| `<leader>l` | 在当前 buffer 内按行 grep |
| `<leader>L` | 在当前 buffer 内搜索光标下 symbol |
| `<leader>m` | 最近打开的文件 |
| `<leader>M` | 最近打开的文件 (仅当前 `.repo` 仓库) |
| `<leader><leader>r` | 在 camera HAL 目录下 live grep |
| `<leader><leader>R` | 在 camera HAL 目录下 grep 光标下 symbol |
| `,fF` | 查找 camera HAL 目录下的文件 |
| `,ff` | 查找当前 git 仓库下的文件 |
| `<leader><leader>l` | 打开 Lazy |
| `<leader>fP` | 查找插件文件 (lazy 目录) |
| `<M-t>` | 异步任务列表 (`asynctasks`) |
| `<M-r>` | 列出 `.repo` 下所有 git 仓库(读缓存)，选中后用 explorer 打开 |
| `<M-R>` | 同上，但强制重新扫描并刷新 `.repo_gits` 缓存 |
| `go` | 恢复上一个 picker |
| `<F3>` | 用 explorer 打开当前文件所在目录 |
| `<F15>` (S-F3) | 用 explorer 打开当前文件所在 git 根目录 |
| `<F4>` | 用 explorer 打开当前 `.repo` 根目录 |
| `<F16>` (S-F4) | 用 explorer 打开用户主目录 |
| `<leader><space>` | (禁用 LazyVim 默认的 Find Files) |

### Snacks Explorer

| 快捷键 | 功能 |
|--------|------|
| `\|` | 垂直分屏打开 |
| `-` | 水平分屏打开 |
| `<C-j>` | 在同一目录内的下一个同级节点间移动（跳过已展开目录的子节点） |
| `<C-k>` | 在同一目录内的上一个同级节点间移动（跳过已展开目录的子节点） |

> `<C-j>`/`<C-k>` 由 `lua/plugins/snacks.lua` 中的 `explorer_sibling_next` / `explorer_sibling_prev` 实现：同级判定基于 item 的 `parent` 引用，顶层节点的 `parent` 为 `nil`，同归一组。
>
> 其余 explorer 默认键位（`<BS>` 上级、`l` 进入、`h` 折叠、`a/d/r/c/m` 增删改、`y/p` 复制粘贴、`u` 刷新、`.]g/[g` git、`.]d/[d` 诊断等）仍生效。

### Markdown

| 快捷键 | 功能 |
|--------|------|
| `<A-M><A-M>` | 切换当前 buffer 的 Markdown 渲染 |
| `<A-m><A-m>` | 全局切换 Markdown 渲染 |

### Sidekick (CLI 集成)

| 快捷键 | 模式 | 功能 |
|--------|------|------|
| `<C-.>` | n/t/i/x | 聚焦 CLI 会话 |
| `<leader>aa` | n | 打开 / 关闭 CLI |
| `<leader>as` | n | 选择 CLI |
| `<leader>ad` | n | 断开 CLI 会话 |
| `<leader>at` | n/x | 发送当前符号/选区 |
| `<leader>af` | n | 发送整个文件 |
| `<leader>av` | x | 发送可视选区 |
| `<leader>ap` | n/x | 选择 prompt |
| `<leader>ao` | n | 直接打开 opencode |

## 用户命令

| 命令 | 功能 |
|------|------|
| `:LspLog [level]` | 打开 LSP 日志；带参数时先设置日志级别 (`trace/debug/info/warn/error/off`) 再打开 |
| `:Lua <code>` | 执行 Lua 代码，结果输出到只读的新缓冲区 |

## `.repo` / clangd 支持

`lua/config/config-local.lua` 在 `VimEnter` 时从当前路径向上查找 `.repo` 根目录；若根目录下没有 `.nvim.lua`，则把模板 `config-local/.repo.nvim.lua` 复制过去。

模板 (`.repo.nvim.lua`) 的作用：当仓内存在自带的 `clangd` 时，复用 LazyVim 既有的 clangd 启动参数，仅把可执行文件替换为仓内版本（避免“改完又被 lspconfig 覆盖”）。通过在 `BufReadPre/BufNewFile` 与 `LspAttach` 阶段重新套用并重启非目标客户端的 clangd 来保证最终生效。

## `.repo` 仓库辅助 (snacks_custom)

`lua/snacks_custom.lua` 提供以下辅助函数：

- `camera_dirs(filepath)` — 传入当前文件路径，返回 camera HAL 相关目录列表（自动过滤不存在的路径）；未匹配到任何分组时返回空列表

  仓库根路径通过 `vim.fs.root(filepath, ".repo")` 从当前文件向上查找 `.repo` 目录获取。函数将文件相对仓库根目录的路径与 `dir2dirs` 中每个分组下的每个值做前缀匹配，任一值匹配即把整个分组加入搜索目录。

- `git_repos(filepath, refresh?)` — 递归扫描 `.repo` 根目录下所有含 `.git` 目录的仓库，返回其父目录列表（排序后）；不在 `.repo` 树下时返回 `nil`

  仓库列表优先在 `.repo` 根目录执行 `repo list -p -f` 获取；`repo` 不存在或执行失败时回退为扫描含 `.git` 的目录（依次用 `fd`、`find`、`vim.fs.find`）。结果缓存在 `<repo根>/.repo_gits`，下次存在该文件时直接读取；传 `refresh = true` 可强制重新获取。

- `pick_git_repos(refresh?)` — 用 snacks picker 列出上述仓库，选中后用 explorer 打开；`<M-r>` 读缓存，`<M-R>` 强制刷新

- `pick_async_tasks()` — 调用 `asynctasks#list` 获取任务，用 snacks picker 列出并执行；绑定在 `<M-t>`

- `open_focus_close(dir)` — explorer 的打开/聚焦/关闭逻辑，供目录类快捷键使用

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

## 异步任务

`async_tasks.ini` 定义了两个任务，分别绑定 `<F5>` / `<F9>`：

- **file-run** — 按文件类型执行当前文件（c/cpp 编译后运行、go build 运行、python/node/sh/bash/lua/perl/ruby 解释执行），输出到终端。
- **file-build** — 按文件类型构建（c/cpp 用 `gcc`、go 用 `go build`、make 用 `make`），输出到 quickfix。
