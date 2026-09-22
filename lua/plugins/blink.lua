-- 补全按键 + 关掉代码片段（snippet）
--
-- 1) Tab 也能接受补全：
--      select_and_accept  菜单正显示着 → 选中并接受
--      fallback           菜单没开 → 交回 Neovim 原来的 Tab（也就是缩进）
-- 2) 关掉 snippets 补全源：菜单里不会再出现带 ~ 的片段条目
--    注意 LazyVim 的 sources.default 是“追加”语义，删不掉，所以这里是把
--    snippets 这个 provider 单独禁用（blink 支持 enabled = false）
return {
  {
    "saghen/blink.cmp",
    opts = {
      sources = {
        providers = {
          snippets = { enabled = false },
        },
      },
      keymap = {
        ["<Tab>"] = { "select_and_accept", "fallback" },
        -- 想彻底关掉“回车接受”，把这行改成 ["<CR>"] = false
        ["<CR>"] = { "accept", "fallback" },
      },
    },
  },
}
