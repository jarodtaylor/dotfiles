return {
  { "akinsho/bufferline.nvim", enabled = false },
  { "alker0/chezmoi.vim", enabled = false },
  -- Plugin Configurations
  {
    "catppuccin",
    opts = {
      transparent_background = true,
    },
  },
  {
    "nvim-neo-tree/neo-tree.nvim",
    opts = {
      filesystem = {
        filtered_items = {
          visible = true,
          never_show = {
            ".DS_Store",
          },
        },
      },
    },
  },
  {
    "nvim-lualine/lualine.nvim",
    optional = true,
    opts = {
      sections = {
        lualine_z = {
          function()
            return " " .. os.date("%r")
          end,
        },
      },
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin",
    },
  },
}
