local M = {}

--- Find the repo root by searching upward for a `.repo` directory.
--- @return string|nil repo_root absolute path to the repo root, or nil if not found
function M.find_repo_root()
  local file = vim.api.nvim_buf_get_name(0)
  local dir = file ~= "" and vim.fn.fnamemodify(file, ":h") or vim.fn.getcwd()
  local found = vim.fs.find(".repo", { upward = true, path = dir, type = "directory" })[1]
  if not found then
    return nil
  end
  return vim.fn.fnamemodify(found, ":h")
end

--- Build the list of camera HAL search directories under the repo root.
--- @param repo string repo root path
--- @return string[] dirs list of absolute paths (existing only)
function M.camera_dirs(repo)
  local subdirs = {
    "vendor/hisi/ap/hardware/camera_hal",
    "vendor/hisi/ap/hardware/camera_product",
    "vendor/hisi/ap/include/camera_hal",
    "vendor/hisi/ap/kernel",
    "device/hisi/customize",
    "vendor/hisi/ap/bionic/libc/kernel/uapi",
    "vendor/hisi/ap/platform",
    "vendor/hisi/ffrt/basesrc",
    "vendor/hisi/include/isp",
    "vendor/hisi/isp",
    "vendor/hisi/odm",
    "vendor/huawei/chip_prod/DeviceDriverSubsystem/chip_prod_config_camera",
    "vendor/huawei/chipset/modules/camera_x",
    "vendor/huawei/foundation/multimedia/algorithm_camera",
    "vendor/huawei/prebuilt/odm/hisi",
  }
  local dirs = {}
  for _, sub in ipairs(subdirs) do
    local path = repo .. "/" .. sub
    if vim.fn.isdirectory(path) == 1 then
      table.insert(dirs, path)
    end
  end
  return dirs
end

return M
