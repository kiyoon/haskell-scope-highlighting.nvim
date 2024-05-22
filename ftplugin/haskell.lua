if vim.g.loaded_haskell_scope_highlighting then
	return
end
vim.g.loaded_haskell_scope_highlighting = true

if vim.fn.has("nvim-0.8") ~= 1 then
	vim.notify_once("haskell-scope-highlighting.nvim needs Neovim >= 0.8", vim.log.levels.ERROR)
	return
end

if not vim.g.__haskell_scope_highlighting_setup_completed then
	require("haskell-scope-highlighting").setup({})
end
