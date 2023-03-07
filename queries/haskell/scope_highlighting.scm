
; @function.call from nvim-treesitter/queries/haskell/highlights.scm
; (exp_infix (exp_name) @function.call (#set! "priority" 101))
; (exp_apply . (exp_name (variable) @function.call))
; (exp_apply . (exp_name (qualified_variable (variable) @function.call)))
; (quoter) @function.call

[
 (exp_lambda)
 (function)
 (exp_do)
] @scope


(function name: (variable) @variable_declaration)
(pat_name (variable) @variable_declaration)

(exp_name (variable) @variable_expression (#not-any-of? @variable_expression "return" "otherwise"))
(exp_name (qualified_variable) @variable_expression)

