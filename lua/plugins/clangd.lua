-- clangd 调参：关掉“函数参数占位符”
--
-- LazyVim 默认给 clangd 传了 --function-arg-placeholders，效果是：
-- 你补全 sqrt 时，插进来的不是 "sqrt"，而是 "sqrt(${1:double x})" 这样的
-- 带占位符的模板（光标停在 double x 上，让你直接改）。如果那个占位符没被
-- 替换掉，留在代码里就是非法 C 语句，clangd 立刻刷一屏错误。
-- 这里把参数占位符关掉：补全只插入函数名，参数自己写。
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        clangd = {
          cmd = {
            "clangd",
            "--background-index",
            "--clang-tidy",
            "--header-insertion=iwyu",
            "--completion-style=detailed",
            "--function-arg-placeholders=0", -- 关键：0 = 关闭参数占位符
            "--fallback-style=llvm",
          },
          init_options = {
            usePlaceholders = false,
          },
        },
      },
    },
  },
}
