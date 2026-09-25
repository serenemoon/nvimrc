return {
  {
    "inkarkat/vim-mark",
    dependencies = {
      "inkarkat/vim-ingo-library", -- 必须先安装这个依赖库
    },
    init = function()
      vim.g.mw_no_mappings = true
      -- vim.g.mwDefaultHighlightingPalette = "extended"
      -- vim.g.mwDefaultHighlightingNum = 12
      vim.g.mwDefaultHighlightingPalette = {
        { ctermbg = "Magenta", ctermfg = "Black", guibg = "#FFA1C6", guifg = "#80005D" },
        { ctermbg = "Cyan", ctermfg = "Black", guibg = "#A1FEFF", guifg = "#007F80" },
        { ctermbg = "Yellow", ctermfg = "Black", guibg = "#FFE8A1", guifg = "#806000" },
        { ctermbg = "DarkRed", ctermfg = "Black", guibg = "#F5A1FF", guifg = "#720080" },
        { ctermbg = "DarkGreen", ctermfg = "Black", guibg = "#D0FFA1", guifg = "#3F8000" },
        { ctermbg = "DarkMagenta", ctermfg = "Black", guibg = "#A29CCF", guifg = "#120080" },
        { ctermbg = "Brown", ctermfg = "Black", guibg = "#FFC4A1", guifg = "#803000" },
        { ctermbg = "Black", ctermfg = "Gray", guibg = "#131311", guifg = "#AAAAAA" },
        { ctermbg = "Blue", ctermfg = "White", guibg = "#0000FF", guifg = "#F0F0FF" },
        { ctermbg = "DarkRed", ctermfg = "White", guibg = "#FF0000", guifg = "#FFFFFF" },
        { ctermbg = "DarkGreen", ctermfg = "White", guibg = "#00FF00", guifg = "#355F35" },
        { ctermbg = "DarkYellow", ctermfg = "White", guibg = "#FFFF00", guifg = "#6F6F4C" },
      }
    end,
    -- 如果你不想用默认的 <Leader>m 键位，可以在这里自定义
    keys = {
      { "mm", "<Plug>MarkSet", mode = { "n", "v" }, desc = "Toggle Current word highlighting" },
      { "mr", "<Plug>MarkRegex", mode = { "n", "v" }, desc = "Regex highlighting" },
      { "mn", "<Plug>MarkToggle", mode = { "n" }, desc = "Toggle All highlighting" },
      { "mN", "<Plug>MarkAllClear", mode = { "n" }, desc = "Clear All highlighting" },
      { "m*", "<Plug>MarkSearchCurrentNext", mode = { "n" }, desc = "Search Current Highlight Word Next" },
      { "m#", "<Plug>MarkSearchCurrentPrev", mode = { "n" }, desc = "Search Current Highlight Word Prev" },
      { "m/", "<Plug>MarkSearchAnyNext", mode = { "n" }, desc = "Search Any Highlight Word Next" },
      { "m?", "<Plug>MarkSearchAnyPrev", mode = { "n" }, desc = "Search Any Highlight Word Prev" },
    },
  },
}
