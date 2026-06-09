-- Inside the snacks.nvim Explorer, <C-h> can't reach the left tmux pane the way
-- it does from a normal buffer. The Explorer is a split-layout picker with a
-- hidden "root" window: vim-tmux-navigator's <C-h> runs `wincmd h`, which lands
-- in that root, and snacks immediately bounces focus back into the editor with
-- `wincmd l`. The window number changed, so vim-tmux-navigator concludes it
-- moved within Neovim and never forwards the keystroke to tmux. (<C-l/j/k> don't
-- pass through the root, so they already work.) Fix: in the Explorer only, send
-- <C-h> straight to tmux, bypassing the `wincmd h` that gets bounced. The
-- Explorer is pinned leftmost, so "left" is unambiguously the tmux pane beside it.
vim.api.nvim_create_autocmd("FileType", {
  pattern = "snacks_picker_list",
  callback = function(ev)
    if vim.env.TMUX then
      vim.keymap.set("n", "<C-h>", function()
        vim.fn.system("tmux select-pane -L")
      end, { buffer = ev.buf, desc = "Tmux navigate left (snacks explorer)" })
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
