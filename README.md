# haskell-scope-highlighting.nvim

Neovim plugin that marks the current scope of the cursor, and distinguishes variables that come from within the scope and outside of it.

WIP

## Installation

With lazy.nvim,

```lua
  {
    "kiyoon/haskell-scope-highlighting.nvim",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
    },
  },
```

## Customisation

```vim
hi! link HaskellCurrentScope CursorLine
hi! link HaskellVariableDeclaredWithinScope DiagnosticVirtualTextInfo
hi! link HaskellVariableDeclaredOutsideScope DiagnosticVirtualTextError
```

## Commands

```vim
:HaskellScopeHighlightingToggle
:HaskellScopeHighlightingEnable
:HaskellScopeHighlightingDisable
```
