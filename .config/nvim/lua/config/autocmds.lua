-- Custom autocmds loaded after plugins

-- Highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- Resize splits if window got resized
vim.api.nvim_create_autocmd({ "VimResized" }, {
  callback = function()
    vim.cmd("tabdo wincmd =")
  end,
})

-- Enable wrapping for text-based files
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "markdown", "text", "gitcommit", "rst", "asciidoc", "tex" },
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.linebreak = true
    vim.opt_local.breakindent = true
    vim.opt_local.textwidth = 70
    -- Navigate by visual lines instead of logical lines
    vim.keymap.set('n', 'j', 'gj', { buffer = true })
    vim.keymap.set('n', 'k', 'gk', { buffer = true })
    vim.keymap.set('n', '<Down>', 'gj', { buffer = true })
    vim.keymap.set('n', '<Up>', 'gk', { buffer = true })
  end,
})

-- Disable wrapping for code files and add column guide
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "python", "javascript", "lua", "c", "cpp" },
  callback = function()
    vim.opt_local.wrap = false
    vim.opt_local.textwidth = 0
    vim.opt_local.colorcolumn = "70"
  end,
})
