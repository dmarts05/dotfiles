------------------------
-- General
------------------------
-- Wrap lines
vim.opt.wrap = true

-- Disable breadcrumbs
lvim.builtin.breadcrumbs.active = false

-- Disable next line comment when pressing Enter or o
vim.api.nvim_create_autocmd("FileType", {
	pattern = "*",
	callback = function()
		vim.opt_local.formatoptions:remove({ "r", "o" })
	end,
})

------------------------
-- Plugins
------------------------
lvim.plugins = {
	-- Mason Tool Installer
	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
	},
	-- Coloscheme
	{
		"catppuccin/nvim",
		name = "catppuccin",
		opts = {
			flavour = "mocha",
		},
	},
	-- Surround
	{
		"tpope/vim-surround",

		-- make sure to change the value of `timeoutlen` if it's not triggering correctly, see https://github.com/tpope/vim-surround/issues/117
		-- setup = function()
		--  vim.o.timeoutlen = 500
		-- end
	},
	-- Golang
	"olexsmir/gopher.nvim",
	"leoluz/nvim-dap-go",
}

------------------------
-- Copilot
------------------------
table.insert(lvim.plugins, {
	"zbirenbaum/copilot-cmp",
	event = "InsertEnter",
	dependencies = { "zbirenbaum/copilot.lua" },
	config = function()
		vim.defer_fn(function()
			require("copilot").setup({
				suggestion = {
					auto_trigger = true,
					keymap = {
						accept = "<C-l>",
						accept_word = "<C-S-l>",
						next = "<C-j>",
						prev = "<C-k>",
						dismiss = "<C-h>",
					},
				},
			}) -- https://github.com/zbirenbaum/copilot.lua/blob/master/README.md#setup-and-configuration
			require("copilot_cmp").setup() -- https://github.com/zbirenbaum/copilot-cmp/blob/master/README.md#configuration
		end, 100)
	end,
})

------------------------
-- Theming
------------------------
lvim.colorscheme = "catppuccin-mocha"
lvim.builtin.lualine.options.theme = "catppuccin"

------------------------
-- Mason Tool Installer
------------------------
local mason_tool_installer = require("mason-tool-installer")
mason_tool_installer.setup({
	ensure_installed = {
		"delve",
		"gofumpt",
		"goimports",
		"golangci-lint-langserver",
		"gomodifytags",
		"gopls",
		"gotests",
		"impl",
		"ruff_lsp",
		"staticcheck",
		"stylua",
		"tsserver",
		"tailwindcss",
	},
})

------------------------
-- Treesitter
------------------------
lvim.builtin.treesitter.ensure_installed = {
	"go",
	"gomod",
	"lua",
	"python",
	"typescript",
	"javascript",
	"json",
	"yaml",
	"html",
	"css",
	"tsx",
}

------------------------
-- Formatting
------------------------
local formatters = require("lvim.lsp.null-ls.formatters")
formatters.setup({
	{ name = "stylua", filetypes = { "lua" } },
	{ command = "goimports", filetypes = { "go" } },
	{ command = "gofumpt", filetypes = { "go" } },
})

lvim.format_on_save = true

------------------------
-- Linters
------------------------
local linters = require("lvim.lsp.null-ls.linters")
linters.setup({
	{ command = "staticcheck", filetypes = { "go" } },
})

------------------------
-- Dap
------------------------
local dap_ok, dapgo = pcall(require, "dap-go")
if not dap_ok then
	return
end

dapgo.setup()

------------------------
-- LSP
------------------------
vim.list_extend(lvim.lsp.automatic_configuration.skipped_servers, { "gopls", "pyright" })
lvim.lsp.automatic_configuration.skipped_servers = vim.tbl_filter(function(server)
	return server ~= "ruff_lsp"
end, lvim.lsp.automatic_configuration.skipped_servers)

local lsp_manager = require("lvim.lsp.manager")

lsp_manager.setup("gopls", {
	on_attach = function(client, bufnr)
		require("lvim.lsp").common_on_attach(client, bufnr)
		local _, _ = pcall(vim.lsp.codelens.refresh)
		local map = function(mode, lhs, rhs, desc)
			if desc then
				desc = desc
			end

			vim.keymap.set(mode, lhs, rhs, { silent = true, desc = desc, buffer = bufnr, noremap = true })
		end
		map("n", "<leader>Gi", "<cmd>GoInstallDeps<Cr>", "Install Go Dependencies")
		map("n", "<leader>Gt", "<cmd>GoMod tidy<cr>", "Tidy")
		map("n", "<leader>Ga", "<cmd>GoTestAdd<Cr>", "Add Test")
		map("n", "<leader>GA", "<cmd>GoTestsAll<Cr>", "Add All Tests")
		map("n", "<leader>Ge", "<cmd>GoTestsExp<Cr>", "Add Exported Tests")
		map("n", "<leader>Gg", "<cmd>GoGenerate<Cr>", "Go Generate")
		map("n", "<leader>Gf", "<cmd>GoGenerate %<Cr>", "Go Generate File")
		map("n", "<leader>Gc", "<cmd>GoCmt<Cr>", "Generate Comment")
		map("n", "<leader>GT", "<cmd>lua require('dap-go').debug_test()<cr>", "Debug Test")
	end,
	on_init = require("lvim.lsp").common_on_init,
	capabilities = require("lvim.lsp").common_capabilities(),
	settings = {
		gopls = {
			usePlaceholders = true,
			gofumpt = true,
			codelenses = {
				generate = false,
				gc_details = true,
				test = true,
				tidy = true,
			},
		},
	},
})

local status_ok, gopher = pcall(require, "gopher")
if not status_ok then
	return
end

gopher.setup({
	commands = {
		go = "go",
		gomodifytags = "gomodifytags",
		gotests = "gotests",
		impl = "impl",
		iferr = "iferr",
	},
})

------------------------
-- Custom Keybindings
------------------------

-- Split buffers
lvim.keys.normal_mode["|"] = ":vsplit<CR>"
lvim.keys.normal_mode["-"] = ":split<CR>"

-- Resize with arrows
lvim.keys.normal_mode["<C-S-K>"] = ":resize -2<CR>"
lvim.keys.normal_mode["<C-S-J>"] = ":resize +2<CR>"
lvim.keys.normal_mode["<C-S-L>"] = ":vertical resize -2<CR>"
lvim.keys.normal_mode["<C-S-H>"] = ":vertical resize +2<CR>"

-- Update file with Ctrl + S
lvim.keys.normal_mode["<C-s>"] = ":update<CR>"

-- gj and gk instead of j and k
lvim.keys.normal_mode["j"] = "gj"
lvim.keys.normal_mode["k"] = "gk"
