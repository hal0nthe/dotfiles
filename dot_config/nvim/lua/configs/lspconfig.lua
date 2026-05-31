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
  "lua_ls",
  "rust-analyzer"
}

vim.diagnostic.config({
  virtual_text = false, -- matikan virtual text bawaan
  underline = true,     -- underline tetap aktif
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = " ",
      [vim.diagnostic.severity.WARN] = " ",
      [vim.diagnostic.severity.HINT] = " ",
      [vim.diagnostic.severity.INFO] = " ",
    }
  }
})

vim.lsp.enable(servers)

-- read :h vim.lsp.config for changing options of lsp servers
