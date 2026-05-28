require("nvchad.configs.lspconfig").defaults()

local servers = {
  "html",
  "cssls",
  -- "tailwindcss",
  "pylsp",
  "clangd",
  "gopls",
  "eslint",
  "ts_ls",
}

vim.lsp.enable(servers)

-- read :h vim.lsp.config for changing options of lsp servers
