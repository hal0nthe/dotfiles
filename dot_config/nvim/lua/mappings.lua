require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")
map("n", "<leader>ft", "<cmd>TodoTelescope<cr>")

map("n", "<C-l>", function()
  require("triforce").show_profile()
end)

map("n", "]t", function()
  require("todo-comments").jump_next()
end, { desc = "Next todo comment" })

map("n", "[t", function()
  require("todo-comments").jump_prev()
end, { desc = "Previous todo comment" })

-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")
