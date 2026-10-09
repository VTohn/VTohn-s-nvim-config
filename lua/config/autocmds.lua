-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- 剪贴板：普通 y / Y / dd / p 直接走系统剪贴板（跟 VSCode 习惯一致）。
--
-- 为什么放这里而不是 options.lua：
--   LazyVim 在启动时会把 clipboard 先存进内部变量再置空，等 VeryLazy 事件
--   才恢复（为了延迟加载 xsel/pbcopy 这类慢工具，见 LazyVim config/init.lua）。
--   写在 options.lua 里会被这套「存 → 清空 → 恢复」夹在中间，结果不稳定。
--   本文件本身就是 VeryLazy 时才加载的，再加一层延迟，保证最后设上去的是我们。
--
-- 依赖系统里有 provider：X11 用 xclip 或 xsel，Wayland 用 wl-clipboard。
-- 没有 provider 的话这个设置等于无效（`:checkhealth vim.provider` 可以查）。
-- 想临时用 nvim 内部寄存器：`"0p`（最近一次 yank）或 `"_d`（黑洞寄存器）。
vim.api.nvim_create_autocmd("User", {
  group = vim.api.nvim_create_augroup("UserClipboard", { clear = true }),
  pattern = "VeryLazy",
  desc = "普通 y/Y/d/p 同步系统剪贴板",
  callback = function()
    vim.schedule(function()
      vim.opt.clipboard = "unnamedplus"
    end)
  end,
})
