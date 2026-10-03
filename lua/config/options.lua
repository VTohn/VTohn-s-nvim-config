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

-- Verilog / SystemVerilog 的 filetype 兜底
-- nvim 0.13 对 .v 是按内容嗅探的：正常 RTL 会认成 verilog，
-- 但注释居多 / 近乎空白的 .v 会 fallback 成 v（V 语言），所以这里强制成 verilog。
-- 代价：以后写 V 语言（vlang）的 .v 文件也会被当成 Verilog。
vim.g.filetype_v = "verilog"
-- .vh 在 nvim 里没有默认映射（只有 .sv / .svh → systemverilog），补上
vim.filetype.add({ extension = { vh = "verilog" } })
