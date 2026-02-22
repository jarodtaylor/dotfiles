return {
  "folke/snacks.nvim",
  opts = {
    picker = {
      -- Affects pickers like files, grep, etc.
      hidden = true,
      ignored = true, -- Optional: includes files from .gitignore
    },
    explorer = {
      -- Affects the file explorer specifically
      hidden = true,
    },
  },
}
