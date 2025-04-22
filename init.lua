-- Set leader key
vim.g.mapleader = ","             -- Comma as leader key
-- Basic settings
vim.opt.number = true             -- Show line numbers
vim.opt.foldmethod = "indent"     -- Set indent fold, but with everything unfolded, use (za) to toggle folds
vim.opt.foldlevelstart = 99
vim.opt.tabstop = 4               -- Number of spaces for a tab
vim.opt.shiftwidth = 4            -- Number of spaces for autoindent
vim.opt.expandtab = true          -- Use spaces instead of tabs
vim.opt.smartindent = true        -- Smart indentation
vim.opt.wrap = false              -- Disable line wrapping
vim.opt.termguicolors = true      -- Enable 24-bit RGB colors
vim.opt.clipboard = "unnamedplus" -- Use system clipboard

-- Install lazy.nvim plugin manager
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable", -- latest stable release
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

local servers = { "rust_analyzer", "gopls", "html", "cssls", "terraformls" }
-- Setup lazy.nvim
require("lazy").setup({
    { "nvim-telescope/telescope.nvim", dependencies = { "nvim-lua/plenary.nvim" } },
    -- lsp
    {
        "hrsh7th/cmp-nvim-lsp",
    },
    {
        "neovim/nvim-lspconfig",
    },
    {
        "nvim-treesitter/nvim-treesitter",
        build = ":TSUpdate",
        config = function()
            require("nvim-treesitter.configs").setup({
                highlight = { enable = true },
            })
        end,
    },
    { "williamboman/mason.nvim",       config = true },
    {
        "williamboman/mason-lspconfig.nvim",
        dependencies = { "williamboman/mason.nvim" },
        config = function()
            require("mason-lspconfig").setup({
                ensure_installed = servers,
                automatic_installation = true,
            })
        end,
    },

    { 'NLKNguyen/papercolor-theme' },
    -- dashboard
    { "goolord/alpha-nvim" },
    -- fzf
    { 'junegunn/fzf.vim' },
    { 'junegunn/fzf' },
    -- testing
    { 'vim-test/vim-test' }

})

-- Set Theme as Papercolor
vim.cmd("colorscheme papercolor")


local on_attach = function(client, bufnr)
    local function buf_set_keymap(mode, lhs, rhs, opts)
        opts = opts or { noremap = true, silent = true }
        vim.api.nvim_buf_set_keymap(bufnr, mode, lhs, rhs, opts)
    end

    local function buf_set_option(option, value)
        vim.api.nvim_buf_set_option(bufnr, option, value)
    end

    buf_set_option("omnifunc", "v:lua.vim.l:p.omnifunc")
    buf_set_keymap('n', 'gD', '<Cmd>lua vim.lsp.buf.declaration()<CR>', opts)
    buf_set_keymap('n', 'gd', '<Cmd>lua vim.lsp.buf.definition()<CR>', opts)
    buf_set_keymap('n', 'K', '<Cmd>lua vim.lsp.buf.hover()<CR>', opts)
    buf_set_keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
    buf_set_keymap('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
    buf_set_keymap('n', 'gn', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
    buf_set_keymap('n', '[d', '<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>', opts)
    buf_set_keymap('n', ']d', '<cmd>lua vim.lsp.diagnostic.goto_next()<CR>', opts)

    -- Print a message when the LSP attaches
    print("LSP attached to buffer " .. bufnr)
end

local capabilities = require("cmp_nvim_lsp").default_capabilities()

local lspconfig = require("lspconfig")

for _, server in ipairs(servers) do
    lspconfig[server].setup({
        on_attach = on_attach,
        capabilities = capabilities,
    })
end

local function map(mode, lhs, rhs, opts)
    local options = { noremap = true, silent = true }
    if opts then
        options = vim.tbl_extend('force', options, opts)
    end
    vim.keymap.set(mode, lhs, rhs, options)
end

-- Open Fzf Files window
map('n', '<C-p>', '<cmd>:Files<cr>')
-- Vim Test
map('n', ',tf', '<cmd>:TestFile<cr>')
map('n', ',tt', '<cmd>:TestNearest<cr>')

-- Tab management
map('n', ',tn', '<cmd>:tabnext<cr>')
map('n', ',ts', '<cmd>:tab split<cr>')
map('', '<leader>l', vim.diagnostic.goto_next)

-- auto fmt *.go files
vim.api.nvim_create_autocmd("BufWritePre", {
    pattern = "*.go",
    callback = function()
        local params = vim.lsp.util.make_range_params()
        params.context = { only = { "source.organizeImports" } }
        local result = vim.lsp.buf_request_sync(0, "textDocument/codeAction", params, 1000)
        for _, res in pairs(result or {}) do
            for _, r in pairs(res.result or {}) do
                if r.edit then
                    vim.lsp.util.apply_workspace_edit(r.edit, "utf-8")
                else
                    vim.lsp.buf.execute_command(r.command)
                end
            end
        end

        vim.lsp.buf.format()
    end,
})

-- Format Lua on save
lspconfig.lua_ls.setup({
    on_attach = function(client, bufnr)
        -- Enable formatting on save
        if client.server_capabilities.documentFormattingProvider then
            vim.api.nvim_create_autocmd("BufWritePre", {
                buffer = bufnr,
                callback = function()
                    vim.lsp.buf.format({ async = false })
                end,
            })
        end
    end,
    settings = {
        Lua = {
            format = {
                enable = true, -- Enable formatting
            },
            diagnostics = {
                globals = { "vim" }, -- Recognize `vim` as a global
            },
        },
    },
})

-- Format Rust on Save
lspconfig.rust_analyzer.setup({
    on_attach = function(client, bufnr)
        -- Enable formatting on save
        if client.server_capabilities.documentFormattingProvider then
            vim.api.nvim_create_autocmd("BufWritePre", {
                buffer = bufnr,
                callback = function()
                    vim.lsp.buf.format({ async = false })
                end,
            })
        end
    end,
    settings = {
        ["rust-analyzer"] = {
            checkOnSave = {
                command = "clippy", -- Optional: Run `clippy` on save for linting
            },
        },
    },
})

local alpha = require("alpha")
local dashboard = require("alpha.themes.dashboard")

-- Set header (ASCII art or text)
dashboard.section.header.val = {
    [[      ███████  ███████  ██████   ██   ██  ██    ██ ██ ███    ███]],
    [[      ██       ██       ██   ██   ██ ██   ██    ██ ██ ████  ████]],
    [[      █████    █████    ██████     ███    ██    ██ ██ ██ ████ ██]],
    [[      ██       ██       ██          ██     ██  ██  ██ ██  ██  ██]],
    [[      ███████  ███████  ██          ██      ████   ██ ██      ██]],
    [[            zzz...                                               ]],
    [[         (\_/)                                                   ]],
    [[         ( -.-)                                                  ]],
    [[         o_(")(")                                                ]],
    [[                                                                 ]],
    [[          Welcome to Eepyvim!                                    ]]
}

-- Set menu buttons
-- ascii art from https://asciimoji.com/
dashboard.section.buttons.val = {
    dashboard.button("f", "  ／人◕ __ ◕人＼ |  Find File", ":Files <CR>"),
    dashboard.button("r", "(✿◠‿◠)            |  Recent Files", ":Telescope oldfiles<CR>"),
    dashboard.button("g", "(´・ω・)っ由      |  Find Word", ":Telescope live_grep<CR>"),
    dashboard.button("c", "  (っˆڡˆς)       |  Config", ":e ~/.config/nvim/init.lua<CR>"),
    dashboard.button("u", "꒰ ꒡⌓꒡꒱        |  Update Plugins", ":Lazy sync<CR>"),
    dashboard.button("q", "ʕノ•ᴥ•ʔノ ︵ ┻━┻  |  Touch Grass", ":qa<CR>"),
}

dashboard.section.footer.val = { "" }

-- Apply the dashboard configuration
alpha.setup(dashboard.config)
