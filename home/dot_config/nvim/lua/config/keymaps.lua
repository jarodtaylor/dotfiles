-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
--

local map = vim.api.nvim_set_keymap
local opts = { noremap = true, silent = true }

-- Disable horizontal scrolling with the mouse wheel
map("n", "<ScrollWheelRight>", "<Nop>", opts)
map("n", "<ScrollWheelLeft>", "<Nop>", opts)

-- Remap Shift + Scroll to act as horizontal scroll
map("n", "<S-ScrollWheelUp>", "<ScrollWheelRight>", opts)
map("n", "<S-ScrollWheelDown>", "<ScrollWheelLeft>", opts)
