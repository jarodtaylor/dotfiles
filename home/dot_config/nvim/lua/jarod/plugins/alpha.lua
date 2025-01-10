return {
  "goolord/alpha-nvim",
  event = "VimEnter",
  config = function()
    local alpha = require("alpha")
    local dashboard = require("alpha.themes.dashboard")
    local utils = require("jarod.utils")
    -- local header = require("jarod.plugins.alpha-headers.neovim")
    local function footer()
      local plugins_count = utils.get_lazy_plugin_count()
      local datetime = os.date("  %m-%d-%Y   %H:%M")
      local version = vim.version()
      local nvim_version_info = "   v" .. version.major .. "." .. version.minor .. "." .. version.patch
      -- local fortune = require("alpha.fortune")
      return datetime .. "   Plugins " .. plugins_count .. nvim_version_info
    end

    dashboard.config.opts = {
      margin = 10
    }

    -- Set the header
    --dashboard.section.header.val = header.ascii
    dashboard.section.header.val = "Jarod is awesome!"

    dashboard.section.buttons.val = {
      dashboard.button("e", "  New File", "<cmd>ene<CR>"),
      dashboard.button("ee", "  Toggle file explorer", "<cmd>NvimTreeToggle<CR>"),
      dashboard.button("ff", "󰈞  Find File", "<cmd>Telescope find_files<CR>"),
      dashboard.button("fg", "  Find Word", "<cmd>Telescope live_grep<CR>"),
      dashboard.button("wr", "󰁯  Restore Session For Current Directory", "<cmd>SessionRestore<CR>"),
      dashboard.button("q", "  Quit NVIM", "<cmd>qa<CR>"),
    }

    dashboard.section.footer.val = footer()
    -- COLORS
    -- dashboard.section.shortcut.opts.hl = "AlphaShortcut"
    dashboard.section.header.opts.hl = "AlphaHeader"
    -- dashboard.section.header.label.opts.hl = "AlphaHeaderLabel"
    dashboard.section.buttons.opts.hl = "AlphaButtons"
    dashboard.section.footer.opts.hl = "AlphaFooter"
    print(dashboard.opts)

    alpha.setup(dashboard.opts)
    vim.cmd([[autocmd FileType alpha setlocal nofoldenable]])
  end,
}
