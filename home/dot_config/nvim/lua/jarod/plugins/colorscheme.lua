return {
  "catppuccin/nvim",
  lazy = false,
  name = "catppuccin",
  priority = 1000,
  config = function()
    local catppuccin = require("catppuccin")
    catppuccin.setup({
      flavour = "mocha", -- latte, frappe, macchiato, mocha
      transparent_background = true, -- disables setting the background color.
      show_end_of_buffer = false, -- shows the '~' characters after the end of buffers
      custom_highlights = function(colors)
        return {
          -- AlphaShortcut = { fg = colors.blue },
          -- AlphaHeader = { fg = colors.blue },
          -- AlphaHeaderLabel = { fg = colors.blue },
          -- AlphaButtons = { fg = colors.blue },
          -- AlphaFooter = { fg = colors.blue, style = { "italic" } },
        }
      end,
      integrations = {
        alpha = true
      }
    })

    vim.cmd.colorscheme("catppuccin")
  end,
}
