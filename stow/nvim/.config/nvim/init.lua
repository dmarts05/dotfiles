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

-- Map Ctrl+S to save
vim.keymap.set({ "n", "i", "v" }, "<C-s>", function()
  vim.cmd.write()
end, { desc = "Save file" })

-- Make j/k move by *display* lines instead of real lines
vim.keymap.set("n", "j", "gj", { noremap = true, silent = true })
vim.keymap.set("n", "k", "gk", { noremap = true, silent = true })

-- Jump multiple lines at a time in normal and visual mode
vim.keymap.set({ "n", "v" }, "<C-d>", "10j", { noremap = true })
vim.keymap.set({ "n", "v" }, "<C-u>", "10k", { noremap = true })

-- Clear search highlights on Escape
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>", { noremap = true, silent = true })

-- Stop newline continuation of comments
vim.api.nvim_create_autocmd("BufEnter", {
    callback = function()
        vim.opt.formatoptions:remove({ "c", "r", "o" })
    end,
    desc = "Disable automatic comment continuation",
})

-- VSCode-specific keybindings and settings
if vim.g.vscode then
    local vscode = require("vscode")

    vim.api.nvim_create_autocmd("TextYankPost", {
        callback = function()
            vim.highlight.on_yank({ higroup = "Search", timeout = 200 })
        end,
    })

    vim.keymap.set("n", "K", function()
        vscode.action("editor.action.showHover")
    end)

    vim.keymap.set({ "n", "v" }, "<space>", function()
        vscode.action("whichkey.show")
    end)

    vim.keymap.set("n", "gcc", function()
        vscode.action("editor.action.commentLine")
    end)

    vim.keymap.set("x", "gc", function()
        vscode.action("editor.action.commentLine")
    end)
end

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
        cond = not vim.g.vscode, 
    },
}

opts = {}

require("lazy").setup(plugins, opts)
