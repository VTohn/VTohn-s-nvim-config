-- Verilog / SystemVerilog 配置（只在 verilog / systemverilog 文件里生效）
--
-- 用到的能力：
--   <leader>cf   手动格式化当前文件
--   <leader>uf   开关全局「保存时自动格式化」（默认开着，走 verible 格式化）
--   补全 = slang-server（verible 自己不带补全）
--   悬停 / 跳转定义 / 引用 / 重命名 / 符号大纲(<leader>cs) / 风格 lint = verible-verilog-ls
--   语法高亮 / 折叠 = treesitter 的 systemverilog parser
--
-- 两个 LSP 是分工的：verible 管格式化 + 风格规则，slang-server 管语义（补全等）。
-- 诊断会有两套来源，这是故意的；嫌吵再回来关掉其中一套。
--
-- 依赖（装一次就行）：
--   :MasonInstall verible slang-server   → LSP / 格式化 / 补全
--   :TSInstall systemverilog             → 高亮 / 折叠
--
-- 说明：nvim-treesitter 的 main 分支没有 verilog parser，只有 systemverilog，
--       所以下面把 verilog 这个 filetype 注册到 systemverilog parser 上，
--       不然 .v 文件没有 treesitter 高亮。
--
-- 项目里可以放的文件（可选）：
--   verible.filelist      多文件项目的文件清单，LSP 默认就读这个名字，
--                         跨文件跳转 / 诊断会更准
--   .rules.verible_lint   lint 规则开关，需要 LSP 带 --rules_config_search
--                         （下面已经加了），会从被分析文件所在目录向上找
-- 注意：verible 的格式化器不会自动读项目里的 .verible-format，
--       要项目级格式化参数得显式传 --flagfile（conform 这边目前没配）。
--
-- 没配仿真（iverilog / verilator / 波形）：需要的话再单独加。

return {
  -- 反引号：Verilog 里 ` 是宏前缀（`define / `RstDisable），不是引号。
  -- LazyVim 默认带 mini.pairs，它的默认表里有
  --     ['`'] = { action = 'closeopen', pair = '``', ... }
  -- 于是打一个 ` 会再补一个闭合的 `（两下才有一个正常反引号，正是之前的毛病）。
  -- 这里只对 verilog / systemverilog 解掉这个 buffer 级映射，
  -- ` 就原样插入；mini.pairs 的括号 / 引号成对行为在别的语言里不受影响。
  {
    "nvim-mini/mini.pairs",
    optional = true,
    init = function()
      local group = vim.api.nvim_create_augroup("VerilogNoBacktickPair", { clear = true })
      vim.api.nvim_create_autocmd("FileType", {
        group = group,
        pattern = { "verilog", "systemverilog" },
        desc = "Verilog 里 ` 不做成对补全",
        callback = function(args)
          vim.keymap.set("i", "`", "`", { buffer = args.buf, desc = "原样插入反引号" })
        end,
      })
    end,
  },

  -- treesitter：装 systemverilog parser，并把 verilog filetype 指过去
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "systemverilog" } },
    init = function()
      -- .v 的 filetype 是 verilog，映射到 systemverilog 的 parser 和查询
      vim.treesitter.language.register("systemverilog", "verilog")
    end,
  },

  -- LSP：verible（格式化 / 风格 lint / 跳转 / 符号大纲）+ slang-server（补全 / 语义）
  -- 写进 servers 之后，LazyVim 会顺带让 Mason 把这两个都装上
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        verible = {
          -- 从被分析文件所在目录向上找 .rules.verible_lint（默认是关的）
          cmd = { "verible-verilog-ls", "--rules_config_search" },
          -- verible 同时支持 push / pull 两种诊断，nvim 会把两套都留下来，
          -- 结果每条诊断显示两遍。这里关掉 pull、只留实时 push，就不重复了。
          on_init = function(client)
            client.server_capabilities.diagnosticProvider = nil
          end,
        },
        -- 补全靠它（verible 不带补全能力）
        -- 注意：lspconfig 默认只认 .git / .slang/ 当工程根标记；
        -- 像 /data/Programme/{VerilogPractice,FPGAproject} 这种没跑过 git 的目录，
        -- root=nil 时 slang-server 基本等于没启动，补全里只剩几个内建类型、
        -- 没有 module / endmodule / case，也没有跨文件的模块名。
        -- 下面先按 .git / .slang/ 找（同 lspconfig 默认），找不到时从文件所在
        -- 目录往上爬，停在「直接包含 .v/.sv 的上一层目录」，这样多文件工程
        -- 不用建任何标记也能索引到同一工程里的其它文件。
        -- 想更精确（include 路径 / 宏定义），仍可在工程根放 .slang/server.json。
        slang_server = {
          root_dir = function(bufnr, on_dir)
            local file = vim.api.nvim_buf_get_name(bufnr)
            if file == "" then
              return
            end
            local dir = vim.fs.dirname(file)

            -- 该目录「直接」含 .v/.sv/.vh/.svh（不递归，递归会一路爬到 /）
            local function has_verilog(d)
              for name, t in vim.fs.dir(d) do
                if t == "file" and name:match("%.s?vh?$") then
                  return true
                end
              end
              return false
            end

            local cur = dir
            while true do
              -- 有标记就以标记为准，优先于下面的兜底
              for _, marker in ipairs({ ".git", ".slang" }) do
                if vim.uv.fs_stat(cur .. "/" .. marker) then
                  return on_dir(cur)
                end
              end
              local parent = vim.fs.dirname(cur)
              if parent == cur or parent == nil then
                break
              end
              -- 爬到「上一层里有同级 verilog 文件」为止，找不到就用文件自身目录
              if has_verilog(parent) then
                return on_dir(parent)
              end
              cur = parent
            end
            on_dir(dir)
          end,
        },
      },
    },
  },

  -- 格式化：conform.nvim 自带 verible formatter（verible-verilog-format）
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        verilog = { "verible" },
        systemverilog = { "verible" },
      },
      formatters = {
        -- verible 默认缩进 2 空格，跟你 options.lua 里的 4 空格对不上，这里统一成 4。
        -- 注意：命令行参数优先级高于项目里的 .verible-format，
        -- 所以想按项目调缩进，直接改这一行（或删掉，用 verible 默认的 2 空格）。
        verible = { prepend_args = { "--indentation_spaces=4" } },
      },
    },
  },
}
