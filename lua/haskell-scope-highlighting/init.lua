local M = {}

local highlighter = require("haskell-scope-highlighting.highlighter")
local options = require("haskell-scope-highlighting.options")

function M.setup(opts)
	options.opts = vim.tbl_deep_extend("force", {}, options.default_opts, opts)

	highlighter.setup(options.opts)

	vim.g.__haskell_scope_highlighting_setup_completed = true
end

return M
