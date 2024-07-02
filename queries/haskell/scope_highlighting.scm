
; NOTE: These commented queries are outdated, for tree-sitter-haskell < v0.21
; @function.call from nvim-treesitter/queries/haskell/highlights.scm
; (exp_infix (exp_name) @function.call (#set! "priority" 101))
; (exp_apply . (exp_name (variable) @function.call))
; (exp_apply . (exp_name (qualified_variable (variable) @function.call)))
; (quoter) @function.call

[
 (expression/lambda)
 (decl/function)
 (expression/do)
 (decl/signature)
] @scope

(decl/function name: (variable) @variable_declaration)
(pattern/variable) @variable_declaration
(expression/variable) @variable_expression (#not-any-of? @variable_expression "return" "otherwise")
(expression/qualified (variable) @variable_expression)

