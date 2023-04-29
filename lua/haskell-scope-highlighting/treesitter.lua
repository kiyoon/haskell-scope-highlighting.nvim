local parsers = require("nvim-treesitter.parsers")
local queries = require("nvim-treesitter.query")
local ts_utils = require("nvim-treesitter.ts_utils")
local ts = require("nvim-treesitter.compat")

local M = {}

function M.is_in_node_range(node, line, col)
	local start_line, start_col, end_line, end_col = node:range()
	if line >= start_line and line <= end_line then
		if line == start_line and line == end_line then
			return col >= start_col and col < end_col
		elseif line == start_line then
			return col >= start_col
		elseif line == end_line then
			return col < end_col
		else
			return true
		end
	else
		return false
	end
end

--- Get the best match at a given point
--- If the point is inside a node, the smallest node is returned
--- If the point is not inside a node, the closest node is returned (if opts.lookahead or opts.lookbehind is true)
---@param matches table list of matches
---@param row number 0-indexed
---@param col number 0-indexed
---@param opts table lookahead and lookbehind options
local best_match_at_point = function(matches, row, col, opts)
	local match_length
	local smallest_range
	local earliest_start

	local lookahead_match_length
	local lookahead_largest_range
	local lookahead_earliest_start
	local lookbehind_match_length
	local lookbehind_largest_range
	local lookbehind_earliest_start

	for _, m in pairs(matches) do
		if m.node and M.is_in_node_range(m.node, row, col) then
			local length = ts_utils.node_length(m.node)
			if not match_length or length < match_length then
				smallest_range = m
				match_length = length
			end
			-- for nodes with same length take the one with earliest start
			if match_length and length == smallest_range then
				local start = m.start
				if start then
					local _, _, start_byte = m.start.node:start()
					if not earliest_start or start_byte < earliest_start then
						smallest_range = m
						match_length = length
						earliest_start = start_byte
					end
				end
			end
		elseif opts.lookahead then
			local start_line, start_col, start_byte = m.node:start()
			if start_line > row or start_line == row and start_col > col then
				local length = ts_utils.node_length(m.node)
				if
					not lookahead_earliest_start
					or lookahead_earliest_start > start_byte
					or (lookahead_earliest_start == start_byte and lookahead_match_length < length)
				then
					lookahead_match_length = length
					lookahead_largest_range = m
					lookahead_earliest_start = start_byte
				end
			end
		elseif opts.lookbehind then
			local start_line, start_col, start_byte = m.node:start()
			if start_line < row or start_line == row and start_col < col then
				local length = ts_utils.node_length(m.node)
				if
					not lookbehind_earliest_start
					or lookbehind_earliest_start < start_byte
					or (lookbehind_earliest_start == start_byte and lookbehind_match_length > length)
				then
					lookbehind_match_length = length
					lookbehind_largest_range = m
					lookbehind_earliest_start = start_byte
				end
			end
		end
	end

	local get_range = function(match)
		if match.metadata ~= nil then
			return match.metadata.range
		end

		return { match.node:range() }
	end

	if smallest_range then
		if smallest_range.start then
			local start_range = get_range(smallest_range.start)
			local node_range = get_range(smallest_range)
			return { start_range[1], start_range[2], node_range[3], node_range[4] }, smallest_range.node
		else
			return get_range(smallest_range), smallest_range.node
		end
	elseif lookahead_largest_range then
		return get_range(lookahead_largest_range), lookahead_largest_range.node
	elseif lookbehind_largest_range then
		return get_range(lookbehind_largest_range), lookbehind_largest_range.node
	end
end

--- Sort matches from smallest to largest
---@param matches table list of matches
---@param row number 0-indexed
---@param col number 0-indexed
local sort_matches_at_point = function(matches, row, col)
	local matches_at_point = {}
	for _, m in pairs(matches) do
		if m.node and M.is_in_node_range(m.node, row, col) then
			table.insert(matches_at_point, m)
		end
	end

	table.sort(matches_at_point, function(a, b)
		local a_length = ts_utils.node_length(a.node)
		local b_length = ts_utils.node_length(b.node)
		if a_length == b_length then
			if a.start and b.start then
				local _, _, a_start_byte = a.start.node:start()
				local _, _, b_start_byte = b.start.node:start()
				return a_start_byte < b_start_byte
			else
				return false
			end
		else
			return a_length < b_length
		end
	end)

	return matches_at_point
end

--- Get the best match at a given point
---@param pos table {row, col} 0-indexed
function M.capture_at_point(query_string, query_group, pos, bufnr, opts)
	query_group = query_group or "scope_highlighting"
	opts = opts or {}
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	local lang = parsers.get_buf_lang(bufnr)
	if not lang then
		return
	end

	local row, col = unpack(pos or vim.api.nvim_win_get_cursor(0))

	if not string.match(query_string, "^@.*") then
		error('Captures must start with "@"')
		return
	end

	local matches = queries.get_capture_matches_recursively(bufnr, query_string, query_group)
	local range, node = best_match_at_point(matches, row, col, opts)
	return bufnr, range, node
end

--- Get the matches at a given point, smallest to largest
---@param pos table {row, col} 0-indexed
function M.captures_at_point_sorted(query_string, query_group, pos, bufnr)
	query_group = query_group or "scope_highlighting"
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	local lang = parsers.get_buf_lang(bufnr)
	if not lang then
		return
	end

	local row, col = unpack(pos or vim.api.nvim_win_get_cursor(0))

	if not string.match(query_string, "^@.*") then
		error('Captures must start with "@"')
		return
	end

	local matches = queries.get_capture_matches_recursively(bufnr, query_string, query_group)
	local matches_at_point = sort_matches_at_point(matches, row, col)
	return bufnr, matches_at_point
end

function M.captures(query_string, query_group, bufnr, opts)
	query_group = query_group or "scope_highlighting"
	opts = opts or {}
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	local lang = parsers.get_buf_lang(bufnr)
	if not lang then
		return
	end

	if not string.match(query_string, "^@.*") then
		error('Captures must start with "@"')
		return
	end

	local matches = queries.get_capture_matches_recursively(bufnr, query_string, query_group)
	local match_nodes = {}
	for _, m in pairs(matches) do
		table.insert(match_nodes, m.node)
	end
	return bufnr, match_nodes
end

function M.matches_within_node(matches, node, bufnr, opts)
	opts = opts or {}
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	local lang = parsers.get_buf_lang(bufnr)
	if not lang then
		return
	end

	local filtered_matches = {}
	for _, m in pairs(matches) do
		local range = { vim.treesitter.get_node_range(m) }
		if m and vim.treesitter.node_contains(node, range) then
			table.insert(filtered_matches, m)
		end
	end
	return bufnr, filtered_matches
end

function M.unique_node_texts(nodes, bufnr)
	local texts_in_key = {}
	for _, node in pairs(nodes) do
		local text = ts.get_node_text(node, bufnr)

		if text ~= nil then
			texts_in_key[text] = true
		end
	end

	local texts = {}
	for text, _ in pairs(texts_in_key) do
		table.insert(texts, text)
	end
	return texts, texts_in_key
end

return M
