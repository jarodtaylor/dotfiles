return {
  -- Seamless C-h/j/k/l navigation across Neovim splits AND tmux panes.
  -- The tmux half lives in ~/.config/tmux/tmux.conf (inline bind-key lines).
  -- Safe to lazy-load: the tmux side does the "is this pane running vim?" check,
  -- so Neovim only needs to register these commands/keys.
  {
    "christoomey/vim-tmux-navigator",
    cmd = {
      "TmuxNavigateLeft",
      "TmuxNavigateDown",
      "TmuxNavigateUp",
      "TmuxNavigateRight",
      "TmuxNavigatePrevious",
      "TmuxNavigatorProcessList",
    },
    keys = {
      { "<c-h>", "<cmd><C-U>TmuxNavigateLeft<cr>" },
      { "<c-j>", "<cmd><C-U>TmuxNavigateDown<cr>" },
      { "<c-k>", "<cmd><C-U>TmuxNavigateUp<cr>" },
      { "<c-l>", "<cmd><C-U>TmuxNavigateRight<cr>" },
      { "<c-\\>", "<cmd><C-U>TmuxNavigatePrevious<cr>" },
    },
  },

  -- Keeps a live Session.vim in the cwd so tmux-resurrect's
  -- @resurrect-strategy-nvim 'session' can restore your Neovim session
  -- (open buffers/layout) after a reboot. No configuration needed.
  { "tpope/vim-obsession" },
}
