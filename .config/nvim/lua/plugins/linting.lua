return {
  {
    "mfussenegger/nvim-lint",
    event = "BufReadPre",
    opts = {
      -- Event to trigger linters
      events = { "BufWritePost", "BufReadPost", "InsertLeave" },
      linters_by_ft = {
        javascript = { "eslint_d" },
        typescript = { "eslint_d" },
        javascriptreact = { "eslint_d" },
        typescriptreact = { "eslint_d" },
        python = { "flake8" },
        lua = { "luacheck" },
        fish = { "fish" },
        sh = { "shellcheck" },
        bash = { "shellcheck" },
        yaml = { "yamllint" },
        -- markdown = { "markdownlint" },
      },
      linters = {
        eslint_d = {
          args = {
            "--no-warn-ignored",
            "--format",
            "json",
            "--stdin",
            "--stdin-filename",
            function()
              return vim.api.nvim_buf_get_name(0)
            end,
          },
        },
        luacheck = {
          args = {
            "--globals", "vim",
            "--read-globals", "awesome client mouse screen",
            "--formatter", "plain",
            "--codes",
            "--ranges",
            "-",
          },
        },
      },
    },
    config = function(_, opts)
      local lint = require("lint")
      
      -- Set up linters
      for name, linter in pairs(opts.linters) do
        if type(linter) == "table" and type(lint.linters[name]) == "table" then
          lint.linters[name] = vim.tbl_deep_extend("force", lint.linters[name], linter)
        else
          lint.linters[name] = linter
        end
      end
      
      lint.linters_by_ft = opts.linters_by_ft
      
      -- Debounce function to avoid excessive linting
      local function debounce(ms, fn)
        local timer = vim.uv.new_timer()
        return function(...)
          local argv = { ... }
          timer:start(ms, 0, function()
            timer:stop()
            vim.schedule_wrap(fn)(unpack(argv))
          end)
        end
      end
      
      -- Main lint function
      local function lint_file()
        local names = lint._resolve_linter_by_ft(vim.bo.filetype)
        names = vim.list_extend({}, names)
        
        -- Add fallback linters
        if #names == 0 then
          vim.list_extend(names, lint.linters_by_ft["_"] or {})
        end
        
        -- Add global linters
        vim.list_extend(names, lint.linters_by_ft["*"] or {})
        
        -- Filter out linters that don't exist
        local ctx = { filename = vim.api.nvim_buf_get_name(0) }
        ctx.dirname = vim.fn.fnamemodify(ctx.filename, ":h")
        
        names = vim.tbl_filter(function(name)
          local linter = lint.linters[name]
          if not linter then
            vim.notify("Linter not found: " .. name, vim.log.levels.WARN)
            return false
          end
          return not (type(linter) == "table" and linter.condition and not linter.condition(ctx))
        end, names)
        
        -- Run linters
        if #names > 0 then
          lint.try_lint(names)
        end
      end
      
      -- Set up autocommands
      vim.api.nvim_create_autocmd(opts.events, {
        group = vim.api.nvim_create_augroup("nvim-lint", { clear = true }),
        callback = debounce(100, lint_file),
      })
    end,
  },
}
