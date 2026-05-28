require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")

map("n", "<C-l>", function()
  require("triforce").show_profile()
end)

-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")
