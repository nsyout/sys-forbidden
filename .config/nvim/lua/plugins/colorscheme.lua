return {
  {
    'kepano/flexoki-neovim', 
    name = 'flexoki',
    priority = 1000, -- Load colorscheme first
    config = function()
      -- Apply colorscheme
      vim.cmd.colorscheme("flexoki-dark")
    end,
  },
  
  -- Universal colorscheme integration for all themes
  {
    "folke/lazy.nvim", -- Using lazy as a dummy plugin to run this config
    priority = 999,
    config = function()
      -- Ensure all UI elements use whatever colorscheme is active
      vim.api.nvim_create_autocmd("ColorScheme", {
        pattern = "*",
        callback = function()
          -- Force which-key to use colorscheme colors
          vim.api.nvim_set_hl(0, "WhichKey", { link = "Normal" })
          vim.api.nvim_set_hl(0, "WhichKeyDesc", { link = "Function" })
          vim.api.nvim_set_hl(0, "WhichKeyGroup", { link = "Keyword" })
          vim.api.nvim_set_hl(0, "WhichKeyValue", { link = "Comment" })
          vim.api.nvim_set_hl(0, "WhichKeyFloat", { link = "NormalFloat" })
          vim.api.nvim_set_hl(0, "WhichKeyBorder", { link = "FloatBorder" })
          
          -- Trouble window colors
          vim.api.nvim_set_hl(0, "TroubleNormal", { link = "Normal" })
          vim.api.nvim_set_hl(0, "TroubleNormalNC", { link = "NormalNC" })
          
          -- Terminal colors
          vim.api.nvim_set_hl(0, "TerminalNormal", { link = "Normal" })
        end,
      })
    end,
  },
}
