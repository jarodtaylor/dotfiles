-- <C-h> from the snacks.nvim Explorer can't reach the left tmux pane the way it
-- does from a normal buffer. The Explorer is a split-layout picker with a hidden
-- "root" window: vim-tmux-navigator's <C-h> runs `wincmd h`, lands in that root,
-- and snacks bounces focus back into the editor with `wincmd l`. The window
-- number changed, so the navigator concludes it moved within Neovim and never
-- forwards to tmux. (<C-l/j/k> don't pass through the root, so they already work.)
--
-- Fix: rebind <C-h> on the picker list buffer to go straight to the left tmux
-- pane, bypassing the bounced `wincmd h`. This attaches to every picker's list
-- window, not just the Explorer — but that's harmless: from any list-window left
-- edge the normal navigator would forward to tmux anyway, so the result matches.
-- The augroup's clear=true keeps a re-source (`:Lazy reload`) from stacking
-- duplicate autocmds (and thus duplicate buffer-local maps).
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("snacks_picker_tmux_nav", { clear = true }),
  pattern = "snacks_picker_list",
  callback = function(ev)
    if vim.env.TMUX then
      vim.keymap.set("n", "<C-h>", function()
        vim.fn.system("tmux select-pane -L")
      end, { buffer = ev.buf, desc = "Tmux navigate left (snacks picker list)" })
    end
  end,
})

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
