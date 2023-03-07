# haskell-scope-highlighting.nvim

Acutally useful context highlighting, that distinguishes variables that come from within the scope (i.e. bound variable) and outside of it (i.e. free variable).

This plugin mainly does these two.

1. Scope indication
2. Free variable, bound variable highlighting


![image](https://user-images.githubusercontent.com/12980409/223523834-9417290e-37f1-4b37-aa6f-1cb264b2d502.png)  
(Other highlightings have been turned off to describe its effect better)  

WIP

## Inspiration

Original idea inspired by prof. Douglas Crockford known as [Context Coloring (Click to see on YouTube)](https://youtu.be/b0EF0VTs9Dc?t=899).  
![Context Coloring](https://user-images.githubusercontent.com/12980409/223306767-f3f3f92b-f88a-4ad1-80b4-80bd7826a321.png)

The idea has been expanded for Haskell with dynamic scope under the cursor by @lionhairdino.

## Installation

With lazy.nvim,

```lua
  {
    "kiyoon/haskell-scope-highlighting.nvim",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
    },
    init = function()
      -- Consider disabling other highlighting
      vim.cmd [[autocmd FileType haskell syntax off]]
      vim.cmd [[autocmd FileType haskell TSDIsable highlight]]
    end
  },
```

## Customisation

Link highlight groups

```vim
hi! link HaskellCurrentScope CursorLine
hi! link HaskellVariableDeclaredWithinScope DiagnosticVirtualTextInfo
hi! link HaskellVariableNotDeclaredWithinFile DiagnosticVirtualTextError
" .....
```

or assign colours on your own.

```vim
hi! HaskellCurrentScope guibg=black

hi! HaskellParentScope1 guibg=#111111
hi! HaskellParentScope2 guibg=#222222
hi! HaskellParentScope3 guibg=#333333
" hi! HaskellParentScope4 .....
" hi! HaskellParentScope5 .....
" ..........

hi! HaskellVariableDeclarationWithinScope guifg=blue
hi! HaskellVariableDeclaredWithinScope guifg=lightblue

hi! HaskellVariableDeclaredWithinParent1 guifg=orange
hi! HaskellVariableDeclaredWithinParent2 guifg=orange
hi! HaskellVariableDeclaredWithinParent3 guifg=orange
" hi! HaskellVariableDeclaredWithinParent4 .......
" hi! HaskellVariableDeclaredWithinParent5 .......
" ..........

hi! HaskellVariableDeclaredWithinFile guifg=orange
hi! HaskellVariableNotDeclaredWithinFile guifg=red

```

## Commands

```vim
:HaskellScopeHighlightingToggle
:HaskellScopeHighlightingEnable
:HaskellScopeHighlightingDisable
```
