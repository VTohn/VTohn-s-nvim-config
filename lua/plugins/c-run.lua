-- C / C++ 相关配置（只在 c / cpp 文件里生效）
--
--   <leader>rb   只编译；错误/警告进 quickfix（有错就自动打开）
--   <leader>rr   编译 + 运行：编译通过才跑，浮动终端里可以交互输入
--   <leader>rR   不重新编译，直接再跑一次
--   另外：c/cpp 的保存时格式化走 clangd → clang-format，
--         风格由 ~/.clang-format 决定（已经配成 4 空格、不折行）
--
-- 编译器用系统的 gcc / g++（LazyVim 不带编译器）。
-- 编译选项想改就改下面的 flags。

local flags = {
  c = { "gcc", "-std=gnu11", "-Wall", "-Wextra", "-g", "-O2" },
  cpp = { "g++", "-std=c++17", "-Wall", "-Wextra", "-g", "-O2" },
}

-- gcc / g++ 的输出格式，用来解析进 quickfix
local EFM = table.concat({
  "%f:%l:%c: %trror: %m", -- file:line:col: error: ...
  "%f:%l:%c: %tarning: %m", -- file:line:col: warning: ...
  "%f:%l:%c: %m",
  "%f:%l: %m",
}, ",")

local function bufname(buf)
  local name = vim.api.nvim_buf_get_name(buf)
  return name ~= "" and name or nil
end

-- 可执行文件 = 源文件去掉扩展名
local function binary(buf)
  local name = bufname(buf)
  return name and vim.fn.fnamemodify(name, ":r") or nil
end

local function compile_args(buf)
  local name = bufname(buf)
  local argv = vim.deepcopy(flags[vim.bo[buf].filetype] or flags.c)
  vim.list_extend(argv, { name, "-o", vim.fn.fnamemodify(name, ":r") })
  vim.list_extend(argv, { "-lm" }) -- 链接数学库（sqrt/pow 这类函数要用）
  return argv
end

---@return boolean ok
local function build(buf)
  if not bufname(buf) then
    vim.notify("文件还没保存，先 :w", vim.log.levels.WARN, { title = "C Build" })
    return false
  end
  vim.cmd("silent! update") -- 存盘（会顺带触发 LazyVim 的格式化）

  -- 不用 :make，因为 :make 拿不到退出码，直接跑编译器更准
  local res = vim.system(compile_args(buf), { text = true }):wait()
  local lines = vim.split((res.stdout or "") .. (res.stderr or ""), "\n", { trimempty = true })
  vim.fn.setqflist({}, "r", {
    title = "build: " .. vim.fn.fnamemodify(bufname(buf), ":t"),
    lines = lines,
    efm = EFM,
  })

  if res.code ~= 0 then
    vim.cmd("copen")
    vim.notify("编译失败，见 quickfix", vim.log.levels.ERROR, { title = "C Build" })
    return false
  end
  if #vim.fn.getqflist() > 0 then
    vim.cmd("copen") -- 只有 warning 也让你看一眼
    vim.notify("编译通过（有警告）", vim.log.levels.WARN, { title = "C Build" })
  else
    vim.cmd("cclose")
    vim.notify("编译通过 → " .. vim.fn.fnamemodify(binary(buf), ":t"), vim.log.levels.INFO, { title = "C Build" })
  end
  return true
end

local function run(buf)
  local name, bin = bufname(buf), binary(buf)
  if not name or not bin or vim.fn.filereadable(bin) == 0 then
    vim.notify("还没有可执行文件，先 <leader>rb", vim.log.levels.WARN, { title = "C Run" })
    return
  end
  local cwd = vim.fn.fnamemodify(name, ":h")
  local old = Snacks.terminal.get({ bin }, { cwd = cwd, create = false })
  if old then
    old:destroy() -- 同一个程序只留一个终端窗口，跑完不清屏方便看输出
  end
  Snacks.terminal.open({ bin }, { cwd = cwd, interactive = true, auto_close = false })
end

return {
  {
    "LazyVim/LazyVim",
    init = function()
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "c", "cpp" },
        callback = function(ev)
          -- 保存时自动格式化保持开启（LazyVim 默认），风格由 clang-format 决定：
          --   ~/.clang-format  → 4 空格、不折行
          --   项目里放 .clang-format 可以覆盖它
          -- 不想要自动格式化：<leader>uF（当前文件）/<leader>uf（全局），
          -- 或者在这里加一句 vim.b[ev.buf].autoformat = false

          -- 顺手把 :make 也配好，习惯用 :make 的话可以直接用
          local argv = vim.deepcopy(flags[vim.bo[ev.buf].filetype] or flags.c)
          -- %:S = 文件名按 shell 转义；-lm 放在最后，链接数学库
          vim.list_extend(argv, { "%:S", "-o", "%:r:S", "-lm" })
          vim.bo[ev.buf].makeprg = table.concat(argv, " ")
          vim.bo[ev.buf].errorformat = EFM

          local function map(lhs, fn, desc)
            vim.keymap.set("n", lhs, fn, { buffer = ev.buf, desc = desc })
          end
          map("<leader>rb", function()
            build(ev.buf)
          end, "Build 编译")
          map("<leader>rr", function()
            if build(ev.buf) then
              run(ev.buf)
            end
          end, "Build & Run 编译并运行")
          map("<leader>rR", function()
            run(ev.buf)
          end, "Run 只运行")
        end,
      })
    end,
  },
  {
    "folke/which-key.nvim",
    optional = true,
    opts = { spec = { { "<leader>r", group = "run" } } },
  },
}
