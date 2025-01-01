local _ENV = (getgenv or getfenv)()

local Implementations = {}

-- from number to boolean
function Implementations.toBoolean(n)
	return n ~= 0
end

-- an easy way to escape string, most developers better code like this!!!!
function Implementations.toEscapedString(s)
	if type(s) == "string" then
		local hasQuotationMarks = string.find(s, '"') ~= nil
		local hasApostrophes = string.find(s, "'") ~= nil

		if hasQuotationMarks and hasApostrophes then
			return "[[" ..s.. "]]"
		elseif hasQuotationMarks and not hasApostrophes then
			return "'" ..s.. "'"
		end

		return '"' ..s.. '"'
	end

	return tostring(s)
end

-- picks indexing method based on characters in a string
function Implementations.formatIndexString(s)
	if type(s) == "string" then
		local validDirectPattern = "^[%a_][%w_]*$"
		if string.find(s, validDirectPattern) then
			return `.{s}`
		end
		return `["{s}"]`
	end

	return tostring(s)
end

-- add left side character padding to x
function Implementations.padLeft(x, char, padding)
	return string.rep(char, padding - #tostring(x)) .. x
end

-- add right side character padding to x
function Implementations.padRight(x, char, padding)
	return x .. string.rep(char, padding - #tostring(x))
end

-- returns true if passed string is a key pointing to a Roblox global
function Implementations.isGlobal(s)
	return _ENV[s] ~= nil
end

return Implementations
