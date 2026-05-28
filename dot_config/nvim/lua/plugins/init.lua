return {
  {
    "stevearc/conform.nvim",
    -- event = 'BufWritePre', -- uncomment for format on save
    opts = require "configs.conform",
  },

  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        "gopls",
      },
    }
  },

  {
    "neovim/nvim-lspconfig",
    config = function()
      require "configs.lspconfig"
    end,
  },

  {
    "IogaMaster/neocord",
    event = "VeryLazy",
    config = function()
      require "configs.discord"
    end,
  },

  {
    "shellRaining/hlchunk.nvim",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      require "configs.chunk"
    end,
  },

  {
    "rachartier/tiny-inline-diagnostic.nvim",
    event = "VeryLazy",
    priority = 1000,
    config = function()
      require "configs.diagnostics"

      vim.diagnostic.config({ virtual_text = false }) -- Disable Neovim's default virtual text diagnostics
    end,
  },

  {
    "hrsh7th/nvim-cmp",
    -- dependencies = {
    --   {
    --     "supermaven-inc/supermaven-nvim",
    --     opts = {},
    --   },
    -- },
    -- opts = function(_, opts)
    --   opts.sources[1].trigger_chars = { "-" }
    --   table.insert(opts.sources, 1, { name = "supermaven" })
    -- end,
  },

  {
    "gisketch/triforce.nvim",
    dependencies = { "nvzone/volt" },
    config = function()
      require "configs.triforce"
    end,
  },

-- Matugen
  -- {
  --   "matugen-theme",
  --   dir = vim.fn.stdpath("config"),
  --   lazy = false,
  --   priority = 1000,
  --   config = function()
  --     require("configs.matugen").load()
  --   end,
  -- },
  --
  {
  'mrcjkb/rustaceanvim',
    -- To avoid being surprised by breaking changes,
    -- I recommend you set a version range
    version = '^9',
    -- This plugin implements proper lazy-loading (see :h lua-plugin-lazy).
    -- No need for lazy.nvim to lazy-load it.
    lazy = false,
  },
  -- test new blink
  -- { import = "nvchad.blink.lazyspec" },

  {
  	"nvim-treesitter/nvim-treesitter",
    lazy = false,
    build = ":TSUpdate",
  	opts = {
  		ensure_installed = {
  			"vim", "lua", "vimdoc",
       "html", "css", "rust"
  		},
  	},
  },
}
