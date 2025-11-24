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
vim.opt.syntax = "on"
vim.opt.errorbells = false
vim.opt.smartcase = true
vim.opt.showmode = false


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
        "hrsh7th/nvim-cmp",
        dependencies = {
            "hrsh7th/cmp-nvim-lsp",     -- LSP source for nvim-cmp
            "hrsh7th/cmp-buffer",       -- Buffer completions
            "hrsh7th/cmp-path",         -- Path completions
            "hrsh7th/cmp-cmdline",      -- Command-line completions
            "L3MON4D3/LuaSnip",         -- Snippet engine
            "saadparwaiz1/cmp_luasnip", -- Snippet completions
        },
    },
    {
        "hrsh7th/vim-vsnip",
    },
    {
        "onsails/lspkind.nvim"
    },
    {
        "ray-x/lsp_signature.nvim",
    },
    {
        "tpope/vim-fugitive",
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
    local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end
    local function buf_set_option(...) vim.api.nvim_buf_set_option(bufnr, ...) end

    -- Mappings.
    local opts = { noremap = true, silent = true }
    require('lsp_signature').on_attach({
        bind = true,
        doc_lines = 0,
        floating_window = false,
        hint_scheme = 'Comment',
    })

    buf_set_option("omnifunc", "v:lua.vim.l:p.omnifunc")
    buf_set_keymap('n', 'gD', '<Cmd>lua vim.lsp.buf.declaration()<CR>', opts)
    buf_set_keymap('n', 'gd', '<Cmd>lua vim.lsp.buf.definition()<CR>', opts)
    buf_set_keymap('n', 'K', '<Cmd>lua vim.lsp.buf.hover()<CR>', opts)
    buf_set_keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
    buf_set_keymap('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
    buf_set_keymap('n', 'gn', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
    buf_set_keymap('n', '[d', '<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>', opts)
    buf_set_keymap('n', ']d', '<cmd>lua vim.lsp.diagnostic.goto_next()<CR>', opts)

    vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(
        vim.lsp.diagnostic.on_publish_diagnostics, {
            -- disable virtual text
            virtual_text = true,

            -- show signs
            signs = true,

            -- delay update diagnostics
            update_in_insert = true,
        }
    )
end

local capabilities = require("cmp_nvim_lsp").default_capabilities(
    vim.lsp.protocol.make_client_capabilities()
)
-- local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities.textDocument.completion.completionItem.snippetSupport = true
capabilities.textDocument.completion.completionItem.resolveSupport = {
    properties = {
        'documentation',
        'detail',
        'additionalTextEdits',
    }
}
-- Configure LSP servers using vim.lsp.config + vim.lsp.enable
for _, server in ipairs(servers) do
    vim.lsp.config(server, {
        on_attach = on_attach,
        capabilities = capabilities,
        flags = {
            debounce_text_changes = 150,
        },
    })
    -- Enable the config so it will start when opening matching files
    pcall(vim.lsp.enable, server)
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

-- Auto fmt *.hcl files
-- To install hcl fmt run go install github.com/hashicorp/hcl/v2/cmd/hclfmt@latest
vim.api.nvim_create_autocmd("BufWritePost", {
    pattern = "*.hcl",
    callback = function()
        if vim.fn.executable("hclfmt") == 0 then
            vim.notify("hclfmt command not found. Install with: go install github.com/hashicorp/hcl/v2/cmd/hclfmt@latest", vim.log.levels.ERROR)
            return
        end
        local file = vim.fn.expand("%:p")
        vim.fn.system("hclfmt -w " .. vim.fn.shellescape(file))
        vim.cmd("edit!")
    end,
})

vim.lsp.config('rust_analyzer', {
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
            checkOnSave = { command = "clippy" },
        },
    },
})
pcall(vim.lsp.enable, 'rust_analyzer')

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

local cmp = require('cmp')
local lspkind = require('lspkind')

local has_words_before = function()
  local line, col = unpack(vim.api.nvim_win_get_cursor(0))
  return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
end

local cmp_kinds = {
    Text = '  ',
    Method = '  ',
    Function = '  ',
    Constructor = '  ',
    Field = '  ',
    Variable = '  ',
    Class = '  ',
    Interface = '  ',
    Module = '  ',
    Property = '  ',
    Unit = '  ',
    Value = '  ',
    Enum = '  ',
    Keyword = '  ',
    Snippet = '  ',
    Color = '  ',
    File = '  ',
    Reference = '  ',
    Folder = '  ',
    EnumMember = '  ',
    Constant = '  ',
    Struct = '  ',
    Event = '  ',
    Operator = '  ',
    TypeParameter = '  ',
}

cmp.setup({
    formatting = {
        format = function(_, vim_item)
            vim_item.kind = (cmp_kinds[vim_item.kind] or '') .. vim_item.kind
            return vim_item
        end,

        -- format = lspkind.cmp_format(),
    },
    snippet = {
        expand = function(args)
            vim.fn["vsnip#anonymous"](args.body) -- For `vsnip` users.
        end,
    },
    mapping = {
        ['<CR>'] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
        ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
                cmp.select_next_item()
            elseif vim.fn["vsnip#available"](1) == 1 then
                feedkey("<Plug>(vsnip-expand-or-jump)", "")
            elseif has_words_before() then
                cmp.complete()
            else
                fallback() -- The fallback function sends a already mapped key. In this case, it's probably `<Tab>`.
            end
        end, { "i", "s" }),
        ["<S-Tab>"] = cmp.mapping(function()
            if cmp.visible() then
                cmp.select_prev_item()
            elseif vim.fn["vsnip#jumpable"](-1) == 1 then
                feedkey("<Plug>(vsnip-jump-prev)", "")
            end
        end, { "i", "s" }),
    },
    sources = cmp.config.sources({
        { name = 'nvim_lsp' },
        { name = 'vsnip' }, -- For vsnip users.
    }, {
        { name = 'buffer' },
    })
})


cmp.setup.filetype({ 'markdown', 'help' }, {
    sources = {
        { name = 'path' },
        { name = 'buffer' },
    },
    completion = {
        autocomplete = false
    }
})

require('nvim-treesitter.configs').setup {
    ensure_installed = { "go", "lua", "vim", "vimdoc" },
    highlight = {
        enable = true,
    },
    indent = {
        enable = true
    }
}
