-- These are configurations for included plugins with LazyVim
return {
  --Disabled
  { "akinsho/bufferline.nvim", enabled = false },
  -- Plugin Configurations
  {
    "catppuccin",
    opts = {
      transparent_background = true,
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
