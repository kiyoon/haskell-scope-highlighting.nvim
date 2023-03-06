if !has('nvim-0.8')
  echohl WarningMsg
  echom "haskell-scope-highlighting.nvim needs Neovim >= 0.8"
  echohl None
  finish
endif

if !exists('g:__haskell_scope_highlighting_setup_completed')
    lua require("haskell-scope-highlighting").setup {}
endif

