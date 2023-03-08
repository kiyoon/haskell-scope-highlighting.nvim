# haskell-scope-highlighting.nvim

Acutally useful context highlighting, that distinguishes variables that come from within the scope (i.e. bound variable) and outside of it (i.e. free variable).

This plugin mainly does these two.

1. Scope indication
2. Free variable, bound variable highlighting

 [Screencast from 07-03-23 20:06:09.webm](https://user-images.githubusercontent.com/12980409/223540476-e8e33ced-ed41-402b-ac95-f3faa5b592e2.webm)
 
- Blue: Variabled defined within the current scope  
- Green: Variable defined within the parent scope
- Orange: Variable NOT defined within the file

(Other highlightings have been turned off to describe its effect better)  

You can add different colours for each depth of scope.  
![Peek_2023-03-08_23-37](https://user-images.githubusercontent.com/12980409/223754740-22d2f934-b6c7-4b66-b56f-f678b95bb0e8.gif)

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

If you want to see only up to depth 1, you can just set the same colour for Parent2, 3, ..., N.  

### Partially enable nvim-treesitter highlighting.

Dynamic context highlighting can be used with treesitter highlighting, but it can be distracting to have all highlighting enabled.  
If you feel the same, you can configure treesitter highlighting yourself.

Create a file in `~/.config/nvim/queries/haskell/highlights.scm` to define treesitter highlighting on your own.  
You can find [the query file from nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter/blob/master/queries/haskell/highlights.scm).

<details>
<summary>
Click to see an example partial highlighting setup.
</summary>

```scm
(con_unit) @symbol  ; unit, as in ()

(comment) @comment

;; ----------------------------------------------------------------------------
;; Functions and variables

(variable) @variable
(pat_wildcard) @variable
(signature name: (variable) @variable)

(function
  name: (variable) @function
  patterns: (patterns))
(function
  name: (variable) @function
  rhs: (exp_lambda))
((signature (variable) @function (fun)) . (function (variable)))
((signature (variable) @_type (fun)) . (function (variable) @function) (#eq? @function @_type))
((signature (variable) @function (context (fun))) . (function (variable)))
((signature (variable) @_type (context (fun))) . (function (variable) @function) (#eq? @function @_type))
((signature (variable) @function (forall (context (fun)))) . (function (variable)))
((signature (variable) @_type (forall (context (fun)))) . (function (variable) @function) (#eq? @function @_type))

(exp_infix (variable) @operator)  ; consider infix functions as operators
(exp_section_right (variable) @operator) ; partially applied infix functions (sections) also get highlighted as operators
(exp_section_left (variable) @operator)

(exp_infix (exp_name) @function.call (#set! "priority" 101))
(exp_apply . (exp_name (variable) @function.call))
(exp_apply . (exp_name (qualified_variable (variable) @function.call)))


;; ----------------------------------------------------------------------------
;; Types

(type) @type
(type_star) @type
(type_variable) @type

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
