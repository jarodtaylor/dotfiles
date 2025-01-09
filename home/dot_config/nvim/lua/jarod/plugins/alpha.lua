return {
  "goolord/alpha-nvim",
  event = "VimEnter",
  config = function()
    local alpha = require("alpha")
    local dashboard = require("alpha.themes.dashboard")
    
    local guy_fawkes = require("jarod.plugins.alpha-headers.guy-fawkes")
    
    -- Apply the highlights
    for group, spec in pairs(guy_fawkes.highlights) do
      vim.api.nvim_set_hl(0, group, spec)
    end
    
    -- Set the header
    dashboard.section.header.val = guy_fawkes.header
    dashboard.section.header.opts = guy_fawkes.opts

    -- Rest of your existing configuration
    dashboard.section.buttons.val = {
      dashboard.button("e", "  New File", "<cmd>ene<CR>"),
      dashboard.button("ee", "  Toggle file explorer", "<cmd>NvimTreeToggle<CR>"),
      dashboard.button("ff", "󰈞  Find File", "<cmd>Telescope find_files<CR>"),
      dashboard.button("fg", "  Find Word", "<cmd>Telescope live_grep<CR>"),
      dashboard.button("wr", "󰁯  Restore Session For Current Directory", "<cmd>SessionRestore<CR>"),
      dashboard.button("q", "  Quit NVIM", "<cmd>qa<CR>"),
    }  

    alpha.setup(dashboard.opts)
    vim.cmd([[autocmd FileType alpha setlocal nofoldenable]])
  end,
}

   