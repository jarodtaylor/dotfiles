return {
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        hidden = true, -- for hidden files
        ignored = true, -- for .gitignore files
        source = {
          files = {
            hidden = true, -- for file finder
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
}
