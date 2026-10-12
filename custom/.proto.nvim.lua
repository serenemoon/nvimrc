-- 把 mingw 加入到环境变量PATH
if vim.fn.has("win32") or vim.fn.has("win64") then
  local mingw_path = "C:\\ProgramData\\mingw64\\mingw64\\bin"
  if vim.fn.isdirectory(mingw_path) then
    vim.env.PATH = mingw_path .. ";" .. vim.env.PATH
  end
end
