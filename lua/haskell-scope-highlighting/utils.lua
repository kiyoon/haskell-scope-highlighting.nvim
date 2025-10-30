local M = {}

function M.wildcard_to_regex(pattern)
	local reg = pattern:gsub("([^%w])", "%%%1"):gsub("%%%*", ".*")
	if not vim.startswith(reg, ".*") then
		reg = "^" .. reg
	end
	if not vim.endswith(reg, ".*") then
		reg = reg .. "$"
	end
	return reg
end

function M.string_wildcard_match(str, pattern)
	return str:match(M.wildcard_to_regex(pattern))
end

function M.list_wildcard_match(str, patterns)
	for _, pattern in ipairs(patterns) do
		if M.string_wildcard_match(str, pattern) ~= nil then
			return true
		end
	end
	return false
end

return M
