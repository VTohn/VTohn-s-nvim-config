-- 补全：只覆盖三个按键，别的一律不动。
--
-- ⚠️ 两个已经踩过的坑，写在这里防止再犯：
--   1) 不要在这个 spec 里写 `config = function(_, opts) ... end`。
--      LazyVim 那条 blink spec 的 config 里才调用 blink.cmp.setup(opts)，
--      你写了就会把它整个替换掉 → blink 根本没初始化 → verilog 和 C 的补全一起消失。
--      要改 opts 用 opts（表或函数），要过滤候选用下面的 transform_items。
--   2) 不要把 provider 写成 `snippets = { enabled = false }`。
--      provider 是整表替换，会把 blink 需要的 module 字段一起抹掉，源直接报废。
--      要过滤就用 transform_items，原来的 provider 字段全部保留。
return {
  {
    "saghen/blink.cmp",
    opts = {
      keymap = {
        -- 菜单开着：Tab 上下选；菜单没开：交回 Neovim 的 Tab（缩进）
        ["<Tab>"] = { "select_next", "fallback" },
        -- 菜单开着：回车确认；菜单没开：换行
        ["<CR>"] = { "accept", "fallback" },
        -- 反引号不拦截按键，原样插入（` 是 verilog 宏前缀）
        ["`"] = false,
      },
      sources = {
        providers = {
          snippets = {
            -- 清掉 UVM 噪音：friendly-snippets 的 systemverilog 片段里 152 条有 134 条
            -- 是 UVM（`uvm_info / uvm_object_utils / uvm_field …），会挤进补全菜单。
            -- transform_items 是官方的候选变换钩子，只过滤条目，不影响源本身。
            transform_items = function(_, items)
              local kept = {}
              for _, item in ipairs(items) do
                local label = tostring(item.label or "")
                if not label:lower():find("uvm", 1, true) then
                  kept[#kept + 1] = item
                end
              end
              return kept
            end,
          },
        },
      },
    },
  },
}
