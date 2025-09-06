return {
  -- Treesitter syntax highlighting
  {
    "nvim-treesitter/nvim-treesitter",
    version = false, -- last release is way too old
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    cmd = { "TSUpdateSync", "TSUpdate", "TSInstall" },
    keys = {
      { "<c-space>", desc = "Increment Selection" },
      { "<bs>", desc = "Decrement Selection", mode = "x" },
    },
    opts = {
      highlight = { enable = true },
      indent = { enable = true },
      ensure_installed = {
        "bash",
        "c",
        "css",
        "diff",
        "go",
        "html",
        "javascript",
        "jsdoc",
        "json",
        "jsonc",
        "lua",
        "luadoc",
        "markdown",
        "markdown_inline",
        "python",
        "query",
        "regex",
        "rust",
        "toml",
        "tsx",
        "typescript",
        "vim",
        "vimdoc",
        "xml",
        "yaml",
      },
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "<C-space>",
          node_incremental = "<C-space>",
          scope_incremental = false,
          node_decremental = "<bs>",
        },
      },
      textobjects = {
        move = {
          enable = true,
          goto_next_start = { 
            ["]f"] = "@function.outer", 
            ["]c"] = "@class.outer", 
            ["]a"] = "@parameter.inner" 
          },
          goto_next_end = { 
            ["]F"] = "@function.outer", 
            ["]C"] = "@class.outer", 
            ["]A"] = "@parameter.inner" 
          },
          goto_previous_start = { 
            ["[f"] = "@function.outer", 
            ["[c"] = "@class.outer", 
            ["[a"] = "@parameter.inner" 
          },
          goto_previous_end = { 
            ["[F"] = "@function.outer", 
            ["[C"] = "@class.outer", 
            ["[A"] = "@parameter.inner" 
          },
        },
      },
    },
    config = function(_, opts)
      require("nvim-treesitter.configs").setup(opts)
    end,
  },

  -- Treesitter textobjects
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    event = "VeryLazy",
    dependencies = "nvim-treesitter/nvim-treesitter",
  },

  -- Auto close HTML/JSX tags
  {
    "windwp/nvim-ts-autotag",
    event = "BufReadPre",
    dependencies = "nvim-treesitter/nvim-treesitter",
    opts = {},
  },
}
