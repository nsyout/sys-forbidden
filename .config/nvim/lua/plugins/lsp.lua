return {
  -- mason-lspconfig bridges mason.nvim and lspconfig
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "mason.nvim" },
    opts = {
      ensure_installed = {
        "lua_ls",
        "ts_ls", -- TypeScript/JavaScript
        "pyright", -- Python
        "rust_analyzer", -- Rust
        "gopls", -- Go
        "html", -- HTML
        "cssls", -- CSS
        "jsonls", -- JSON
        "harper_ls", -- Grammar checker
      },
    },
  },

  -- LSP Configuration
  {
    "neovim/nvim-lspconfig",
    event = "BufReadPre",
    dependencies = {
      "mason.nvim",
      "mason-lspconfig.nvim",
    },
    opts = {
      -- Diagnostic configuration
      diagnostics = {
        underline = true,
        update_in_insert = false,
        virtual_text = {
          spacing = 4,
          source = "if_many",
          prefix = "●",
        },
        severity_sort = true,
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = "✘",
            [vim.diagnostic.severity.WARN] = "▲",
            [vim.diagnostic.severity.HINT] = "⚑",
            [vim.diagnostic.severity.INFO] = "»",
          },
        },
      },
      
      -- Inlay hints (Neovim >= 0.10.0)
      inlay_hints = {
        enabled = true,
        exclude = { "vue" },
      },
      
      -- Global capabilities
      capabilities = {
        workspace = {
          fileOperations = {
            didRename = true,
            willRename = true,
          },
        },
      },
      
      -- LSP server settings
      servers = {
        lua_ls = {
          settings = {
            Lua = {
              workspace = {
                checkThirdParty = false,
              },
              completion = {
                callSnippet = "Replace",
              },
              hint = {
                enable = true,
                paramType = true,
                paramName = "Disable",
                semicolon = "Disable",
                arrayIndex = "Disable",
              },
            },
          },
        },
        
        ts_ls = {
          settings = {
            typescript = {
              inlayHints = {
                includeInlayParameterNameHints = "literal",
                includeInlayParameterNameHintsWhenArgumentMatchesName = false,
                includeInlayFunctionParameterTypeHints = true,
                includeInlayVariableTypeHints = false,
                includeInlayPropertyDeclarationTypeHints = true,
                includeInlayFunctionLikeReturnTypeHints = true,
                includeInlayEnumMemberValueHints = true,
              },
            },
            javascript = {
              inlayHints = {
                includeInlayParameterNameHints = "all",
                includeInlayParameterNameHintsWhenArgumentMatchesName = false,
                includeInlayFunctionParameterTypeHints = true,
                includeInlayVariableTypeHints = true,
                includeInlayPropertyDeclarationTypeHints = true,
                includeInlayFunctionLikeReturnTypeHints = true,
                includeInlayEnumMemberValueHints = true,
              },
            },
          },
        },
        
        pyright = {
          settings = {
            python = {
              analysis = {
                typeCheckingMode = "basic",
              },
            },
          },
        },
        
        gopls = {
          settings = {
            gopls = {
              hints = {
                assignVariableTypes = true,
                compositeLiteralFields = true,
                compositeLiteralTypes = true,
                constantValues = true,
                functionTypeParameters = true,
                parameterNames = true,
                rangeVariableTypes = true,
              },
            },
          },
        },
        
        harper_ls = {
          filetypes = { "markdown", "text", "gitcommit", "rst", "asciidoc", "tex" },
          settings = {
            ["harper-ls"] = {
              userDictPath = "",
              workspaceDictPath = "",
              fileDictPath = "",
              linters = {
                SpellCheck = true,
                SpelledNumbers = true,
                AnA = true,
                SentenceCapitalization = true,
                UnclosedQuotes = true,
                WrongQuotes = false,
                LongSentences = true,
                RepeatedWords = true,
                Spaces = true,
                Matcher = true,
                CorrectNumberSuffix = true,
                BoringWords = true,
              },
              codeActions = {
                ForceStable = false,
              },
              markdown = {
                IgnoreLinkTitle = false,
              },
              diagnosticSeverity = "hint",
              isolateEnglish = false,
              dialect = "American",
              maxFileLength = 120000,
              ignoredLintsPath = {},
            },
          },
        },
      },
    },
    
    config = function(_, opts)
      -- Setup diagnostics
      vim.diagnostic.config(opts.diagnostics)
      
      -- Setup LSP keymaps when LSP attaches to buffer
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("UserLspConfig", {}),
        callback = function(ev)
          local opts_keymap = { buffer = ev.buf }
          
          -- Key mappings
          vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts_keymap)
          vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts_keymap)
          vim.keymap.set("n", "K", vim.lsp.buf.hover, opts_keymap)
          vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts_keymap)
          vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, opts_keymap)
          vim.keymap.set("n", "gr", vim.lsp.buf.references, opts_keymap)
          vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts_keymap)
          vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts_keymap)
          vim.keymap.set("n", "<leader>f", function()
            vim.lsp.buf.format({ async = true })
          end, opts_keymap)
          
          -- Enable inlay hints if available
          if opts.inlay_hints.enabled and vim.lsp.inlay_hint then
            vim.lsp.inlay_hint.enable(true, { bufnr = ev.buf })
          end
        end,
      })
      
      -- Setup capabilities for completion
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      
      -- Setup each server
      local lspconfig = require("lspconfig")
      for server, config in pairs(opts.servers) do
        local server_opts = vim.tbl_deep_extend("force", {
          capabilities = capabilities,
        }, config)
        lspconfig[server].setup(server_opts)
      end
    end,
  },
}
