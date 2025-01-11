return {
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
}
