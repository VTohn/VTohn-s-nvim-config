-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- 缩进改成 4 空格（LazyVim 默认是 2）
vim.opt.expandtab = true -- 用空格代替 Tab 字符
vim.opt.tabstop = 4 -- 一个 Tab 显示成几格
vim.opt.shiftwidth = 4 -- 自动缩进 / >> << 的宽度
vim.opt.softtabstop = 4 -- 编辑时按 Tab / Backspace 的宽度

-- 想让某一类文件单独用别的宽度，可以加 autocmd，例如只有 C 用 8 格：
-- vim.api.nvim_create_autocmd("FileType", {
--   pattern = { "c", "cpp" },
--   callback = function()
--     vim.opt_local.tabstop = 8
--     vim.opt_local.shiftwidth = 8
--     vim.opt_local.softtabstop = 8
--   end,
-- })
