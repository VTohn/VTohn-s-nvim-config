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
--   :MasonInstall verible      → verible-verilog-ls(LSP) + verible-verilog-format(格式化)
--   :TSInstall systemverilog   → 高亮 / 折叠
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
        -- 注意：它得能认出工程根（目录里有 .git 或 .slang/）才会索引其它文件；
        -- 认不出来的话只有当前文件能用，跨文件的模块名补全就没有了。
        -- 多文件工程可以在项目根放 .slang/server.json 配 include 路径 / 宏定义。
        slang_server = {},
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
