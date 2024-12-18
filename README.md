# haskell-scope-highlighting.nvim

Actually useful context highlighting, that distinguishes variables that come from within the scope (i.e. bound variable) and outside of it (i.e. free variable).

This plugin mainly does these two.

1. Scope indication
2. Free variable, bound variable highlighting

 [Screencast from 07-03-23 20:06:09.webm](https://user-images.githubusercontent.com/12980409/223540476-e8e33ced-ed41-402b-ac95-f3faa5b592e2.webm)
 
- Blue: Variable defined within the current scope  
- Green: Variable defined within the parent scope
- Orange: Variable NOT defined within the file

(Other highlightings have been turned off to describe its effect better)  

You can add different colours for each depth of scope.  
![Peek_2023-03-08_23-37](https://user-images.githubusercontent.com/12980409/223754740-22d2f934-b6c7-4b66-b56f-f678b95bb0e8.gif)

## Inspiration

The original idea was inspired by prof. Douglas Crockford, known as [Context Coloring (Click to see on YouTube)](https://youtu.be/b0EF0VTs9Dc?t=899).  
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
      vim.cmd [[autocmd FileType haskell TSDisable highlight]]
    end
  },
```

## Customisation

### Configure highlight groups

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

If you want to see only up to depth 1, you can just set the same colour for Parent2, 3, ..., N. The below example shows gradient colour up to Parent10.

```lua
local i = 1
repeat
  -- orange = #dc9271
  local color = string.format("%d guifg=#%02x%02x%02x",i,
    220 - (i*10)% 220,
    92 - (i*20) % 92,
    72 + (i*20) % 184
  )
  vim.cmd("hi HaskellVariableDeclaredWithinParent"..color)
  vim.cmd("hi HaskellParentScope"..i.." guibg=#2d353b")
  i = i + 1
until (i > 10)
```

### Partially enable nvim-treesitter highlighting.

Dynamic context highlighting can be used with tree-sitter highlighting, but having all highlighting enabled can be distracting.  
If you feel the same, you can configure treesitter highlighting yourself.

Create a file in `~/.config/nvim/queries/haskell/highlights.scm` to define treesitter highlighting on your own.  
You can find [the query file from nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter/blob/master/queries/haskell/highlights.scm).

<details>
<summary>
Click to see an example of a partial highlighting setup.
</summary>

```scm
(comment) @comment
(comment) @spell

;; ----------------------------------------------------------------------------
;; Functions and variables

(variable) @variable
(pattern/wildcard) @variable
(decl/signature name: (variable) @variable)

;; ----------------------------------------------------------------------------
;; Types

(type/unit) @type

(type/unit [
  "("
  ")"
] @type)

(type/list [
  "["
  "]"
] @type)
(type/star) @type

(constructor) @constructor

;; ----------------------------------------------------------------------------
;; Quasi-quotes

(quoter) @function.call
; Highlighting of quasiquote_body is handled by injections.scm
```
</details>

## Commands

```vim
:HaskellScopeHighlightingToggle
:HaskellScopeHighlightingEnable
:HaskellScopeHighlightingDisable
```
