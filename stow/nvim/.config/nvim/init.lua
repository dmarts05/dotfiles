-- Add line numbers
vim.opt.number = true
vim.opt.relativenumber = false

-- Remove background
vim.cmd [[
  highlight Normal ctermbg=NONE guibg=NONE
  highlight NonText ctermbg=NONE guibg=NONE
]]

-- Use system clipboard for yank, delete, change, and put operations
vim.opt.clipboard = "unnamedplus"

-- Lazy.nvim setup
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable",
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

-- Plugin configuration
plugins = {
    {
        "kylechui/nvim-surround",
        version = "*",
        event = "VeryLazy",
        config = function()
            require("nvim-surround").setup({})
        end
    },
    {
        'numToStr/Comment.nvim',
        opts = {},
        lazy = false,
    },
}

opts = {}

require("lazy").setup(plugins, opts)
