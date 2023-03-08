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
	local hlgroup = "CursorLine"
	if vim.fn.hlexists("HaskellCurrentScope") == 0 then
		vim.cmd([[hi! link HaskellCurrentScope ]] .. hlgroup)
		vim.o.cursorline = false
	end

	if colorscheme == "tokyonight" then
		for i = 1, 20 do
			if vim.fn.hlexists("HaskellParentScope" .. i) == 0 then
				vim.cmd([[hi! link HaskellParentScope]] .. i .. [[ Pmenu]])
			end
			if vim.fn.hlexists("HaskellVariableDeclaredWithinParent" .. i) == 0 then
				vim.cmd([[hi! link HaskellVariableDeclaredWithinParent]] .. i .. [[ String]])
			end
		end

		if vim.fn.hlexists("HaskellVariableDeclaredWithinFile") == 0 then
			vim.cmd([[hi! link HaskellVariableDeclaredWithinFile Statement]])
		end
		if vim.fn.hlexists("HaskellVariableDeclaredWithinScope") == 0 then
			vim.cmd([[hi! link HaskellVariableDeclaredWithinScope MoreMsg]])
		end
		if vim.fn.hlexists("HaskellVariableDeclarationWithinScope") == 0 then
			vim.cmd([[hi! link HaskellVariableDeclarationWithinScope Type]])
		end

		if vim.fn.hlexists("HaskellVariableNotDeclaredWithinFile") == 0 then
			vim.cmd([[hi! link HaskellVariableNotDeclaredWithinFile @parameter]])
		end
	else
		for i = 1, 20 do
			if vim.fn.hlexists("HaskellParentScope" .. i) == 0 then
				vim.cmd([[hi HaskellParentScope]] .. i .. [[ guibg=black]])
			end
			if vim.fn.hlexists("HaskellVariableDeclaredWithinParent" .. i) == 0 then
				vim.cmd([[hi! HaskellVariableDeclaredWithinParent]] .. i .. [[ guifg=green]])
			end
		end

		hlgroup = "Keyword"
		if vim.fn.hlexists("HaskellVariableDeclaredWithinFile") == 0 then
			vim.cmd([[hi! link HaskellVariableDeclaredWithinFile ]] .. hlgroup)
		end
		if vim.fn.hlexists("HaskellVariableDeclaredWithinScope") == 0 then
			vim.cmd([[hi! HaskellVariableDeclaredWithinScope guifg=lightblue]])
		end
		if vim.fn.hlexists("HaskellVariableDeclarationWithinScope") == 0 then
			vim.cmd([[hi! HaskellVariableDeclarationWithinScope guifg=blue]])
		end

		if vim.fn.hlexists("HaskellVariableNotDeclaredWithinFile") == 0 then
			vim.cmd([[hi! HaskellVariableNotDeclaredWithinFile guifg=orange]])
		end
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

	local cursor_pos = vim.api.nvim_win_get_cursor(0)
	local cursor_row, cursor_col = cursor_pos[1] - 1, cursor_pos[2]

	local bufnr, scope_matches =
		hs_treesitter.captures_at_point_sorted("@scope", "scope_highlighting", { cursor_row, cursor_col }, 0)

	local current_scope = scope_matches[1]
	if current_scope == nil then
		return
	end

	local scope_node = current_scope.node
	local scope_range = { scope_node:range() }

	M.set_hlgroup(bufnr, ns_highlight, scope_range, "HaskellCurrentScope", 90)

	local parent_nodes = {}

	if #scope_matches > 1 then
		for i = 2, #scope_matches do
			local parent_node = scope_matches[i].node
			table.insert(parent_nodes, parent_node)
			local parent_scope_range = { parent_node:range() }
			M.set_hlgroup(bufnr, ns_highlight, parent_scope_range, "HaskellParentScope" .. i, 90 - i)
		end
	end

	local _, variable_declaration_matches =
		hs_treesitter.captures("@variable_declaration", "scope_highlighting", bufnr, {})
	local _, variable_expression_matches =
		hs_treesitter.captures("@variable_expression", "scope_highlighting", bufnr, {})

	local _, variable_declaration_nodes =
		hs_treesitter.matches_within_node(variable_declaration_matches, scope_node, bufnr, {})
	local _, variable_expression_nodes =
		hs_treesitter.matches_within_node(variable_expression_matches, scope_node, bufnr, {})

	local _, declared_variables_in_key = hs_treesitter.unique_node_texts(variable_declaration_nodes, bufnr)
	-- local expr_variables, expr_variabled_in_key = hs_treesitter.unique_node_texts(variable_expression_nodes)
	local _, declared_variables_in_file = hs_treesitter.unique_node_texts(variable_declaration_matches, bufnr)

	local variable_declared_parents = {}

	for i, parent_node in ipairs(parent_nodes) do
		local _, variable_declaration_nodes_in_parent =
			hs_treesitter.matches_within_node(variable_declaration_matches, parent_node, bufnr, {})
		local _, declared_variables = hs_treesitter.unique_node_texts(variable_declaration_nodes_in_parent, bufnr)
		variable_declared_parents[i] = declared_variables
	end

	if variable_declaration_nodes ~= nil then
		for _, node in ipairs(variable_declaration_nodes) do
			local range = { vim.treesitter.get_node_range(node) }
			M.set_hlgroup(bufnr, ns_highlight, range, "HaskellVariableDeclarationWithinScope", 110)
		end
	end

	if variable_expression_nodes ~= nil then
		for _, node in ipairs(variable_expression_nodes) do
			local text = vim.treesitter.query.get_node_text(node, bufnr)

			local range = { vim.treesitter.get_node_range(node) }
			local hlgroup = nil
			if text == nil then
				goto continue
			end
			if declared_variables_in_key[text] then
				hlgroup = "HaskellVariableDeclaredWithinScope"
			else
				for i, declared_in_parents in ipairs(variable_declared_parents) do
					if declared_in_parents[text] then
						hlgroup = "HaskellVariableDeclaredWithinParent" .. i
						break
					end
				end

				if hlgroup == nil then
					if declared_variables_in_file[text] then
						hlgroup = "HaskellVariableDeclaredWithinFile"
					else
						hlgroup = "HaskellVariableNotDeclaredWithinFile"
					end
				end
			end
			M.set_hlgroup(bufnr, ns_highlight, range, hlgroup, 110)

			::continue::
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
