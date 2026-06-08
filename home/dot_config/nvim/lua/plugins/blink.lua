-- The tmux prefix is C-Space, and tmux intercepts the prefix key before the
-- focused app (Neovim) ever sees it. blink.cmp's default <C-Space> binding
-- (toggle completion) would therefore be a dead key inside tmux. Free it so it
-- isn't a phantom binding; LazyVim's blink shows the completion menu
-- automatically as you type, so no manual trigger is needed. If you ever want a
-- manual trigger reachable inside tmux, bind one to a non-prefix key here.
return {
  "saghen/blink.cmp",
  opts = {
    keymap = {
      ["<C-space>"] = {},
    },
  },
}
