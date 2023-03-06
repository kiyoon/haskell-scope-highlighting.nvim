local hs_treesitter = require("haskell-scope-highlighting.treesitter")
local utils = require("haskell-scope-highlighting.utils")
local M = {}

M.options = {
	enable = true, -- separate from shortsighted.enable. Only for highlighting.
}

function M.setup(opts)
	-- If the colourscheme doesn't support Jupynium yet, link to some default highlight groups
	-- Here we can define some default settings per colourscheme.
	local colorscheme = vim.g.colors_name
	if colorscheme == nil then
		colorscheme = ""
	end
	if utils.string_begins_with(colorscheme, "tokyonight") then
		colorscheme = "tokyonight"
	end
	local hlgroup
	if colorscheme == "tokyonight" then
		hlgroup = "CursorLine"
	else
		hlgroup = "CursorLine"
	end
	if vim.fn.hlexists("HaskellCurrentScope") == 0 then
		vim.cmd([[hi! link HaskellCurrentScope ]] .. hlgroup)
	end
	if vim.fn.hlexists("HaskellOutsideScope") == 0 then
		vim.cmd([[hi! link HaskellOutsideScope ]] .. hlgroup)
	end

	hlgroup = "DiagnosticVirtualTextError"
	if vim.fn.hlexists("HaskellVariableDeclaredOutsideScope") == 0 then
		vim.cmd([[hi! link HaskellVariableDeclaredOutsideScope ]] .. hlgroup)
	end
	hlgroup = "DiagnosticVirtualTextInfo"
	if vim.fn.hlexists("HaskellVariableDeclaredWithinScope") == 0 then
		vim.cmd([[hi! link HaskellVariableDeclaredWithinScope ]] .. hlgroup)
	end

	if opts.enable then
		M.enable()
	else
		M.disable()
	end

	M.add_commands()
end

function M.set_autocmd()
	local augroup = vim.api.nvim_create_augroup("haskell-scope-highlighting", {})
	vim.api.nvim_create_autocmd({ "BufWinEnter", "BufWritePost", "CursorMoved", "CursorMovedI", "WinScrolled" }, {
		pattern = "*.hs",
		callback = M.run,
		group = augroup,
	})
end

local ns_highlight = vim.api.nvim_create_namespace("haskell-scope-highlighting")

--- Set highlight group
---@param buffer number
---@param hl_group string
function M.set_hlgroup(buffer, namespace, range, hl_group, priority)
	priority = priority or 99 -- Treesitter uses 100
	pcall(vim.api.nvim_buf_set_extmark, buffer, namespace, range[1], range[2], {
		end_line = range[3],
		end_col = range[4],
		hl_group = hl_group,
		hl_eol = true,
		priority = priority,
	})
end

function M.clear_namespace(namespace)
	vim.api.nvim_buf_clear_namespace(0, namespace, 0, -1)
end

function M.enable()
	M.options.enable = true

	if vim.fn.expand("%:e") == "hs" then
		M.update()
	end
	M.set_autocmd()
end

function M.disable()
	M.options.enable = false

	M.clear_namespace(ns_highlight)
end

function M.toggle()
	if M.options.enable then
		M.disable()
	else
		M.enable()
	end
end

function M.run()
	if M.options.enable then
		M.clear_namespace(ns_highlight)

		M.update()
	end
end

function M.update()
	if not M.options.enable then
		return
	end

	local end_of_file = vim.fn.line("$")

	local cursor_pos = vim.api.nvim_win_get_cursor(0)
	local cursor_row, cursor_col = cursor_pos[1] - 1, cursor_pos[2]

	local bufnr, scope_range, scope_node = hs_treesitter.capture_at_point(
		"@scope",
		"scope_highlighting",
		{ cursor_row, cursor_col },
		0,
		{}
	)

	if scope_range == nil then
		return
	end

	M.set_hlgroup(bufnr, ns_highlight, scope_range, "HaskellCurrentScope", 90)

	local _, variable_declaration_nodes =
		hs_treesitter.captures_within_node("@variable_declaration", "scope_highlighting", scope_node, bufnr, {})
	local _, variable_expression_nodes =
		hs_treesitter.captures_within_node("@variable_expression", "scope_highlighting", scope_node, bufnr, {})

	local _, declared_variables_in_key = hs_treesitter.unique_node_texts(variable_declaration_nodes, bufnr)
	-- local expr_variables, expr_variabled_in_key = hs_treesitter.unique_node_texts(variable_expression_nodes)

	if variable_declaration_nodes ~= nil then
		for _, node in ipairs(variable_declaration_nodes) do
			local range = { vim.treesitter.get_node_range(node) }
			M.set_hlgroup(bufnr, ns_highlight, range, "HaskellVariableDeclaredWithinScope", 110)
		end
	end

	if variable_expression_nodes ~= nil then
		for _, node in ipairs(variable_expression_nodes) do
			local text = vim.treesitter.query.get_node_text(node, bufnr)

			local range = { vim.treesitter.get_node_range(node) }
			local hlgroup
			if text ~= nil and declared_variables_in_key[text] then
				hlgroup = "HaskellVariableDeclaredWithinScope"
			else
				hlgroup = "HaskellVariableDeclaredOutsideScope"
			end
			M.set_hlgroup(bufnr, ns_highlight, range, hlgroup, 110)
		end
	end
end

function M.add_commands()
	vim.api.nvim_create_user_command(
		"HaskellScopeHighlightToggle",
		"lua require('haskell-scope-highlighting.highlighter').toggle()",
		{}
	)
	vim.api.nvim_create_user_command(
		"HaskellScopeHighlightEnable",
		"lua require('haskell-scope-highlighting.highlighter').enable()",
		{}
	)
	vim.api.nvim_create_user_command(
		"HaskellScopeHighlightDisable",
		"lua require('haskell-scope-highlighting.highlighter').disable()",
		{}
	)
end

return M
