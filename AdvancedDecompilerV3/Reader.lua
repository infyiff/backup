-- Not using slow metatables here because we need it fast
local FLOAT_PRECISION = 24

local Reader = {}

function Reader.new(bytecode)
	local stream = buffer.fromstring(bytecode)
	local cursor = 0
	--
	local self = {}

	function self:len()
		return buffer.len(stream)
	end

	function self:nextByte()
		local result = buffer.readu8(stream, cursor)
		cursor += 1
		return result
	end
	function self:nextSignedByte()
		local result = buffer.readi8(stream, cursor)
		cursor += 1
		return result
	end
	function self:nextBytes(count)
		local result = {}
		for i = 1, count do
			table.insert(result, self:nextByte())
		end
		return result
	end

	function self:nextChar()
		local result = string.char(self:nextByte())
		return result
	end

	function self:nextUInt32()
		local result = buffer.readu32(stream, cursor)
		cursor += 4
		return result
	end
	function self:nextInt32()
		local result = buffer.readi32(stream, cursor)
		cursor += 4
		return result
	end

	function self:nextFloat()
		local result = buffer.readf32(stream, cursor)
		cursor += 4
		return tonumber(string.format(`%0.{FLOAT_PRECISION}f`, result))
	end

	function self:nextVarInt()
		local result = 0
		for i = 0, 4 do
			local b = self:nextByte()
			result = bit32.bor(result, bit32.lshift(bit32.band(b, 0x7F), i * 7))
			if not bit32.btest(b, 0x80) then
				break
			end
		end
		return result
	end

	function self:nextString(len)
		len = len or self:nextVarInt()
		if len == 0 then
			return ""
		else
			local result = buffer.readstring(stream, cursor, len)
			cursor += len
			return result
		end
	end

	function self:nextDouble()
		local result = buffer.readf64(stream, cursor)
		cursor += 8
		return result
	end

	return self
end

function Reader:Set(...)
	FLOAT_PRECISION = ...
end

return Reader
