-- https://github.com/luau-lang/luau/raw/master/Common/include/Luau/Bytecode.h

local CASE_MULTIPLIER = 227 -- 0xE3

local Luau = {
	-- Bytecode opcode, part of the instruction header
	OpCode = {
		-- NOP: noop
		{ ["name"] = "NOP", ["type"] = "none" },

		-- BREAK: debugger break
		{ ["name"] = "BREAK", ["type"] = "none" },

		-- LOADNIL: sets register to nil
		-- A: target register
		{ ["name"] = "LOADNIL", ["type"] = "A" },

		-- LOADB: sets register to boolean and jumps to a given short offset (used to compile comparison results into a boolean)
		-- A: target register
		-- B: value (0/1)
		-- C: jump offset
		{ ["name"] = "LOADB", ["type"] = "ABC" },

		-- LOADN: sets register to a number literal
		-- A: target register
		-- D: value (-32768..32767)
		{ ["name"] = "LOADN", ["type"] = "AsD" },

		-- LOADK: sets register to an entry from the constant table from the proto (number/vector/string)
		-- A: target register
		-- D: constant table index (0..32767)
		{ ["name"] = "LOADK", ["type"] = "AD" },

		-- MOVE: move (copy) value from one register to another
		-- A: target register
		-- B: source register
		{ ["name"] = "MOVE", ["type"] = "AB" },

		-- GETGLOBAL: load value from global table using constant string as a key
		-- A: target register
		-- C: predicted slot index (based on hash)
		-- AUX: constant table index
		{ ["name"] = "GETGLOBAL", ["type"] = "AC", ["aux"] = true },

		-- SETGLOBAL: set value in global table using constant string as a key
		-- A: source register
		-- C: predicted slot index (based on hash)
		-- AUX: constant table index
		{ ["name"] = "SETGLOBAL", ["type"] = "AC", ["aux"] = true },

		-- GETUPVAL: load upvalue from the upvalue table for the current function
		-- A: target register
		-- B: upvalue index
		{ ["name"] = "GETUPVAL", ["type"] = "AB" },

		-- SETUPVAL: store value into the upvalue table for the current function
		-- A: source register
		-- B: upvalue index
		{ ["name"] = "SETUPVAL", ["type"] = "AB" },

		-- CLOSEUPVALS: close (migrate to heap) all upvalues that were captured for registers >= target
		-- A: target register
		{ ["name"] = "CLOSEUPVALS", ["type"] = "A" },

		-- GETIMPORT: load imported global table global from the constant table
		-- A: target register
		-- D: constant table index (0..32767); we assume that imports are loaded into the constant table
		-- AUX: 3 10-bit indices of constant strings that, combined, constitute an import path; length of the path is set by the top 2 bits (1,2,3)
		{ ["name"] = "GETIMPORT", ["type"] = "AD", ["aux"] = true },

		-- GETTABLE: load value from table into target register using key from register
		-- A: target register
		-- B: table register
		-- C: index register
		{ ["name"] = "GETTABLE", ["type"] = "ABC" },

		-- SETTABLE: store source register into table using key from register
		-- A: source register
		-- B: table register
		-- C: index register
		{ ["name"] = "SETTABLE", ["type"] = "ABC" },

		-- GETTABLEKS: load value from table into target register using constant string as a key
		-- A: target register
		-- B: table register
		-- C: predicted slot index (based on hash)
		-- AUX: constant table index
		{ ["name"] = "GETTABLEKS", ["type"] = "ABC", ["aux"] = true },

		-- SETTABLEKS: store source register into table using constant string as a key
		-- A: source register
		-- B: table register
		-- C: predicted slot index (based on hash)
		-- AUX: constant table index
		{ ["name"] = "SETTABLEKS", ["type"] = "ABC", ["aux"] = true },

		-- GETTABLEN: load value from table into target register using small integer index as a key
		-- A: target register
		-- B: table register
		-- C: index-1 (index is 1..256)
		{ ["name"] = "GETTABLEN", ["type"] = "ABC" },

		-- SETTABLEN: store source register into table using small integer index as a key
		-- A: source register
		-- B: table register
		-- C: index-1 (index is 1..256)
		{ ["name"] = "SETTABLEN", ["type"] = "ABC" },

		-- NEWCLOSURE: create closure from a child proto; followed by a CAPTURE instruction for each upvalue
		-- A: target register
		-- D: child proto index (0..32767)
		{ ["name"] = "NEWCLOSURE", ["type"] = "AD" },

		-- NAMECALL: prepare to call specified method by name by loading function from source register using constant index into target register and copying source register into target register + 1
		-- A: target register
		-- B: source register
		-- C: predicted slot index (based on hash)
		-- AUX: constant table index
		-- Note that this instruction must be followed directly by CALL; it prepares the arguments
		-- This instruction is roughly equivalent to GETTABLEKS + MOVE pair, but we need a special instruction to support custom __namecall metamethod
		{ ["name"] = "NAMECALL", ["type"] = "ABC", ["aux"] = true },

		-- CALL: call specified function
		-- A: register where the function object lives, followed by arguments; results are placed starting from the same register
		-- B: argument count + 1, or 0 to preserve all arguments up to top (MULTRET)
		-- C: result count + 1, or 0 to preserve all values and adjust top (MULTRET)
		{ ["name"] = "CALL", ["type"] = "ABC" },

		-- RETURN: returns specified values from the function
		-- A: register where the returned values start
		-- B: number of returned values + 1, or 0 to return all values up to top (MULTRET)
		{ ["name"] = "RETURN", ["type"] = "AB" },

		-- JUMP: jumps to target offset
		-- D: jump offset (-32768..32767; 0 means "next instruction" aka "don't jump")
		{ ["name"] = "JUMP", ["type"] = "sD" },

		-- JUMPBACK: jumps to target offset; this is equivalent to JUMP but is used as a safepoint to be able to interrupt while/repeat loops
		-- D: jump offset (-32768..32767; 0 means "next instruction" aka "don't jump")
		{ ["name"] = "JUMPBACK", ["type"] = "sD" },

		-- JUMPIF: jumps to target offset if register is not nil/false
		-- A: source register
		-- D: jump offset (-32768..32767; 0 means "next instruction" aka "don't jump")
		{ ["name"] = "JUMPIF", ["type"] = "AsD" },

		-- JUMPIFNOT: jumps to target offset if register is nil/false
		-- A: source register
		-- D: jump offset (-32768..32767; 0 means "next instruction" aka "don't jump")
		{ ["name"] = "JUMPIFNOT", ["type"] = "AsD" },

		-- JUMPIFEQ, JUMPIFLE, JUMPIFLT, JUMPIFNOTEQ, JUMPIFNOTLE, JUMPIFNOTLT: jumps to target offset if the comparison is true (or false, for NOT variants)
		-- A: source register 1
		-- D: jump offset (-32768..32767; 1 means "next instruction" aka "don't jump")
		-- AUX: source register 2
		{ ["name"] = "JUMPIFEQ", ["type"] = "AsD", ["aux"] = true },
		{ ["name"] = "JUMPIFLE", ["type"] = "AsD", ["aux"] = true },
		{ ["name"] = "JUMPIFLT", ["type"] = "AsD", ["aux"] = true },
		{ ["name"] = "JUMPIFNOTEQ", ["type"] = "AsD", ["aux"] = true },
		{ ["name"] = "JUMPIFNOTLE", ["type"] = "AsD", ["aux"] = true },
		{ ["name"] = "JUMPIFNOTLT", ["type"] = "AsD", ["aux"] = true },

		-- ADD, SUB, MUL, DIV, MOD, POW: compute arithmetic operation between two source registers and put the result into target register
		-- A: target register
		-- B: source register 1
		-- C: source register 2
		{ ["name"] = "ADD", ["type"] = "ABC" },
		{ ["name"] = "SUB", ["type"] = "ABC" },
		{ ["name"] = "MUL", ["type"] = "ABC" },
		{ ["name"] = "DIV", ["type"] = "ABC" },
		{ ["name"] = "MOD", ["type"] = "ABC" },
		{ ["name"] = "POW", ["type"] = "ABC" },

		-- ADDK, SUBK, MULK, DIVK, MODK, POWK: compute arithmetic operation between the source register and a constant and put the result into target register
		-- A: target register
		-- B: source register
		-- C: constant table index (0..255); must refer to a number
		{ ["name"] = "ADDK", ["type"] = "ABC" },
		{ ["name"] = "SUBK", ["type"] = "ABC" },
		{ ["name"] = "MULK", ["type"] = "ABC" },
		{ ["name"] = "DIVK", ["type"] = "ABC" },
		{ ["name"] = "MODK", ["type"] = "ABC" },
		{ ["name"] = "POWK", ["type"] = "ABC" },

		-- AND, OR: perform `and` or `or` operation (selecting first or second register based on whether the first one is truthy) and put the result into target register
		-- A: target register
		-- B: source register 1
		-- C: source register 2
		{ ["name"] = "AND", ["type"] = "ABC" },
		{ ["name"] = "OR", ["type"] = "ABC" },

		-- ANDK, ORK: perform `and` or `or` operation (selecting source register or constant based on whether the source register is truthy) and put the result into target register
		-- A: target register
		-- B: source register
		-- C: constant table index (0..255)
		{ ["name"] = "ANDK", ["type"] = "ABC" },
		{ ["name"] = "ORK", ["type"] = "ABC" },

		-- CONCAT: concatenate all strings between B and C (inclusive) and put the result into A
		-- A: target register
		-- B: source register start
		-- C: source register end
		{ ["name"] = "CONCAT", ["type"] = "ABC" },

		-- NOT, MINUS, LENGTH: compute unary operation for source register and put the result into target register
		-- A: target register
		-- B: source register
		{ ["name"] = "NOT", ["type"] = "AB" },
		{ ["name"] = "MINUS", ["type"] = "AB" },
		{ ["name"] = "LENGTH", ["type"] = "AB" },

		-- NEWTABLE: create table in target register
		-- A: target register
		-- B: table size, stored as 0 for v=0 and ceil(log2(v))+1 for v!=0
		-- AUX: array size
		{ ["name"] = "NEWTABLE", ["type"] = "AB", ["aux"] = true },

		-- DUPTABLE: duplicate table using the constant table template to target register
		-- A: target register
		-- D: constant table index (0..32767)
		{ ["name"] = "DUPTABLE", ["type"] = "AD" },

		-- SETLIST: set a list of values to table in target register
		-- A: target register
		-- B: source register start
		-- C: value count + 1, or 0 to use all values up to top (MULTRET)
		-- AUX: table index to start from
		{ ["name"] = "SETLIST", ["type"] = "ABC", ["aux"] = true },

		-- FORNPREP: prepare a numeric for loop, jump over the loop if first iteration doesn't need to run
		-- A: target register; numeric for loops assume a register layout [limit, step, index, variable]
		-- D: jump offset (-32768..32767)
		-- limit/step are immutable, index isn't visible to user code since it's copied into variable
		{ ["name"] = "FORNPREP", ["type"] = "AsD" },

		-- FORNLOOP: adjust loop variables for one iteration, jump back to the loop header if loop needs to continue
		-- A: target register; see FORNPREP for register layout
		-- D: jump offset (-32768..32767)
		{ ["name"] = "FORNLOOP", ["type"] = "AsD" },

		-- FORGLOOP: adjust loop variables for one iteration of a generic for loop, jump back to the loop header if loop needs to continue
		-- A: target register; generic for loops assume a register layout [generator, state, index, variables...]
		-- D: jump offset (-32768..32767)
		-- AUX: variable count (1..255) in the low 8 bits, high bit indicates whether to use ipairs-style traversal in the fast path
		-- loop variables are adjusted by calling generator(state, index) and expecting it to return a tuple that's copied to the user variables
		-- the first variable is then copied into index; generator/state are immutable, index isn't visible to user code
		{ ["name"] = "FORGLOOP", ["type"] = "AsD", ["aux"] = true },

		-- FORGPREP_INEXT: prepare FORGLOOP with 2 output variables (no AUX encoding), assuming generator is luaB_inext, and jump to FORGLOOP
		-- A: target register (see FORGLOOP for register layout)
		{ ["name"] = "FORGPREP_INEXT", ["type"] = "A" },

		-- removed in v3
		--{ ["name"] = "DEP_FORGLOOP_INEXT", ["type"] = "A" },

		-- FASTCALL3: perform a fast call of a built-in function using 3 register arguments
		-- A: builtin function id (see LuauBuiltinFunction)
		-- B: source argument register
		-- C: jump offset to get to following CALL
		-- AUX: source register 2 in least-significant byte
		-- AUX: source register 3 in second least-significant byte
		{ ["name"] = "FASTCALL3", ["type"] = "ABC", ["aux"] = true },

		-- FORGPREP_NEXT: prepare FORGLOOP with 2 output variables (no AUX encoding), assuming generator is luaB_next, and jump to FORGLOOP
		-- A: target register (see FORGLOOP for register layout)
		{ ["name"] = "FORGPREP_NEXT", ["type"] = "A" },

		-- no longer supported
		--{ ["name"] = "DEP_FORGLOOP_NEXT", ["type"] = "A" },

		-- NATIVECALL: start executing new function in native code
		-- this is a pseudo-instruction that is never emitted by bytecode compiler, but can be constructed at runtime to accelerate native code dispatch
		{ ["name"] = "NATIVECALL", ["type"] = "none" },

		-- GETVARARGS: copy variables into the target register from vararg storage for current function
		-- A: target register
		-- B: variable count + 1, or 0 to copy all variables and adjust top (MULTRET)
		{ ["name"] = "GETVARARGS", ["type"] = "AB" },

		-- DUPCLOSURE: create closure from a pre-created function object (reusing it unless environments diverge)
		-- A: target register
		-- D: constant table index (0..32767)
		{ ["name"] = "DUPCLOSURE", ["type"] = "AD" },

		-- PREPVARARGS: prepare stack for variadic functions so that GETVARARGS works correctly
		-- A: number of fixed arguments
		{ ["name"] = "PREPVARARGS", ["type"] = "A" },

		-- LOADKX: sets register to an entry from the constant table from the proto (number/string)
		-- A: target register
		-- AUX: constant table index
		{ ["name"] = "LOADKX", ["type"] = "A", ["aux"] = true },

		-- JUMPX: jumps to the target offset; like JUMPBACK, supports interruption
		-- E: jump offset (-2^23..2^23; 0 means "next instruction" aka "don't jump")
		{ ["name"] = "JUMPX", ["type"] = "E" },

		-- FASTCALL: perform a fast call of a built-in function
		-- A: builtin function id (see LuauBuiltinFunction)
		-- C: jump offset to get to following CALL
		-- FASTCALL is followed by one of (GETIMPORT, MOVE, GETUPVAL) instructions and by CALL instruction
		-- This is necessary so that if FASTCALL can't perform the call inline, it can continue normal execution
		-- If FASTCALL *can* perform the call, it jumps over the instructions *and* over the next CALL
		-- Note that FASTCALL will read the actual call arguments, such as argument/result registers and counts, from the CALL instruction
		{ ["name"] = "FASTCALL", ["type"] = "AC" },

		-- COVERAGE: update coverage information stored in the instruction
		-- E: hit count for the instruction (0..2^23-1)
		-- The hit count is incremented by VM every time the instruction is executed, and saturates at 2^23-1
		{ ["name"] = "COVERAGE", ["type"] = "E" },

		-- CAPTURE: capture a local or an upvalue as an upvalue into a newly created closure; only valid after NEWCLOSURE
		-- A: capture type, see LuauCaptureType
		-- B: source register (for VAL/REF) or upvalue index (for UPVAL/UPREF)
		{ ["name"] = "CAPTURE", ["type"] = "AB" },

		-- both no longer supported
		--{ ["name"] = "DEP_JUMPIFEQK", ["type"] = "AsD", ["aux"] = true },
		--{ ["name"] = "DEP_JUMPIFNOTEQK", ["type"] = "AsD", ["aux"] = true },

		-- SUBRK, DIVRK: compute arithmetic operation between the constant and a source register and put the result into target register
		-- A: target register
		-- B: constant table index (0..255); must refer to a number
		-- C: source register
		{ ["name"] = "SUBRK", ["type"] = "ABC" },
		{ ["name"] = "DIVRK", ["type"] = "ABC" },

		-- FASTCALL1: perform a fast call of a built-in function using 1 register argument
		-- A: builtin function id (see LuauBuiltinFunction)
		-- B: source argument register
		-- C: jump offset to get to following CALL
		{ ["name"] = "FASTCALL1", ["type"] = "ABC" },

		-- FASTCALL2: perform a fast call of a built-in function using 2 register arguments
		-- A: builtin function id (see LuauBuiltinFunction)
		-- B: source argument register
		-- C: jump offset to get to following CALL
		-- AUX: source register 2 in least-significant byte
		{ ["name"] = "FASTCALL2", ["type"] = "ABC", ["aux"] = true },

		-- FASTCALL2K: perform a fast call of a built-in function using 1 register argument and 1 constant argument
		-- A: builtin function id (see LuauBuiltinFunction)
		-- B: source argument register
		-- C: jump offset to get to following CALL
		-- AUX: constant index
		{ ["name"] = "FASTCALL2K", ["type"] = "ABC", ["aux"] = true },

		-- FORGPREP: prepare loop variables for a generic for loop, jump to the loop backedge unconditionally
		-- A: target register; generic for loops assume a register layout [generator, state, index, variables...]
		-- D: jump offset (-32768..32767)
		{ ["name"] = "FORGPREP", ["type"] = "AsD" },

		-- JUMPXEQKNIL, JUMPXEQKB: jumps to target offset if the comparison with constant is true (or false, see AUX)
		-- A: source register 1
		-- D: jump offset (-32768..32767; 1 means "next instruction" aka "don't jump")
		-- AUX: constant value (for boolean) in low bit, NOT flag (that flips comparison result) in high bit
		{ ["name"] = "JUMPXEQKNIL", ["type"] = "AsD", ["aux"] = true },
		{ ["name"] = "JUMPXEQKB", ["type"] = "AsD", ["aux"] = true },

		-- JUMPXEQKN, JUMPXEQKS: jumps to target offset if the comparison with constant is true (or false, see AUX)
		-- A: source register 1
		-- D: jump offset (-32768..32767; 1 means "next instruction" aka "don't jump")
		-- AUX: constant table index in low 24 bits, NOT flag (that flips comparison result) in high bit
		{ ["name"] = "JUMPXEQKN", ["type"] = "AsD", ["aux"] = true },
		{ ["name"] = "JUMPXEQKS", ["type"] = "AsD", ["aux"] = true },

		-- IDIV: compute floor division between two source registers and put the result into target register
		-- A: target register
		-- B: source register 1
		-- C: source register 2
		{ ["name"] = "IDIV", ["type"] = "ABC" },

		-- IDIVK compute floor division between the source register and a constant and put the result into target register
		-- A: target register
		-- B: source register
		-- C: constant table index (0..255)
		{ ["name"] = "IDIVK", ["type"] = "ABC" },

		-- Enum entry for number of opcodes, not a valid opcode by itself!
		{ ["name"] = "_COUNT", ["type"] = "none" }
	},
	-- Bytecode tags, used internally for bytecode encoded as a string
	BytecodeTag = {
		-- Bytecode version; runtime supports [MIN, MAX]
		LBC_VERSION_MIN = 3,
		LBC_VERSION_MAX = 6,
		-- Type encoding version
		LBC_TYPE_VERSION_MIN = 1,
		LBC_TYPE_VERSION_MAX = 3,
		-- Types of constant table entries
		LBC_CONSTANT_NIL = 0,
		LBC_CONSTANT_BOOLEAN = 1,
		LBC_CONSTANT_NUMBER = 2,
		LBC_CONSTANT_STRING = 3,
		LBC_CONSTANT_IMPORT = 4,
		LBC_CONSTANT_TABLE = 5,
		LBC_CONSTANT_CLOSURE = 6,
		LBC_CONSTANT_VECTOR = 7
	},
	-- Type table tags
	BytecodeType = {
		LBC_TYPE_NIL = 0,
		LBC_TYPE_BOOLEAN = 1,
		LBC_TYPE_NUMBER = 2,
		LBC_TYPE_STRING = 3,
		LBC_TYPE_TABLE = 4,
		LBC_TYPE_FUNCTION = 5,
		LBC_TYPE_THREAD = 6,
		LBC_TYPE_USERDATA = 7,
		LBC_TYPE_VECTOR = 8,
		LBC_TYPE_BUFFER = 9,

		LBC_TYPE_ANY = 15,

		LBC_TYPE_TAGGED_USERDATA_BASE = 64,
		LBC_TYPE_TAGGED_USERDATA_END = 64 + 32,

		LBC_TYPE_OPTIONAL_BIT = bit32.lshift(1, 7), -- 128

		LBC_TYPE_INVALID = 256
	},
	-- Capture type, used in LOP_CAPTURE
	CaptureType = {
		LCT_VAL = 0,
		LCT_REF = 1,
		LCT_UPVAL = 2
	},
	-- Builtin function ids, used in LOP_FASTCALL
	BuiltinFunction = {
		LBF_NONE = 0,

		-- assert()
		LBF_ASSERT = 1,

		-- math.
		LBF_MATH_ABS = 2,
		LBF_MATH_ACOS = 3,
		LBF_MATH_ASIN = 4,
		LBF_MATH_ATAN2 = 5,
		LBF_MATH_ATAN = 6,
		LBF_MATH_CEIL = 7,
		LBF_MATH_COSH = 8,
		LBF_MATH_COS = 9,
		LBF_MATH_DEG = 10,
		LBF_MATH_EXP = 11,
		LBF_MATH_FLOOR = 12,
		LBF_MATH_FMOD = 13,
		LBF_MATH_FREXP = 14,
		LBF_MATH_LDEXP = 15,
		LBF_MATH_LOG10 = 16,
		LBF_MATH_LOG = 17,
		LBF_MATH_MAX = 18,
		LBF_MATH_MIN = 19,
		LBF_MATH_MODF = 20,
		LBF_MATH_POW = 21,
		LBF_MATH_RAD = 22,
		LBF_MATH_SINH = 23,
		LBF_MATH_SIN = 24,
		LBF_MATH_SQRT = 25,
		LBF_MATH_TANH = 26,
		LBF_MATH_TAN = 27,

		-- bit32.
		LBF_BIT32_ARSHIFT = 28,
		LBF_BIT32_BAND = 29,
		LBF_BIT32_BNOT = 30,
		LBF_BIT32_BOR = 31,
		LBF_BIT32_BXOR = 32,
		LBF_BIT32_BTEST = 33,
		LBF_BIT32_EXTRACT = 34,
		LBF_BIT32_LROTATE = 35,
		LBF_BIT32_LSHIFT = 36,
		LBF_BIT32_REPLACE = 37,
		LBF_BIT32_RROTATE = 38,
		LBF_BIT32_RSHIFT = 39,

		-- type()
		LBF_TYPE = 40,

		-- string.
		LBF_STRING_BYTE = 41,
		LBF_STRING_CHAR = 42,
		LBF_STRING_LEN = 43,

		-- typeof()
		LBF_TYPEOF = 44,

		-- string.
		LBF_STRING_SUB = 45,

		-- math.
		LBF_MATH_CLAMP = 46,
		LBF_MATH_SIGN = 47,
		LBF_MATH_ROUND = 48,

		-- raw*
		LBF_RAWSET = 49,
		LBF_RAWGET = 50,
		LBF_RAWEQUAL = 51,

		-- table.
		LBF_TABLE_INSERT = 52,
		LBF_TABLE_UNPACK = 53,

		-- vector ctor
		LBF_VECTOR = 54,

		-- bit32.count
		LBF_BIT32_COUNTLZ = 55,
		LBF_BIT32_COUNTRZ = 56,

		-- select(_, ...)
		LBF_SELECT_VARARG = 57,

		-- rawlen
		LBF_RAWLEN = 58,

		-- bit32.extract(_, k, k)
		LBF_BIT32_EXTRACTK = 59,

		-- get/setmetatable
		LBF_GETMETATABLE = 60,
		LBF_SETMETATABLE = 61,

		-- tonumber/tostring
		LBF_TONUMBER = 62,
		LBF_TOSTRING = 63,

		-- bit32.byteswap(n)
		LBF_BIT32_BYTESWAP = 64,

		-- buffer.
		LBF_BUFFER_READI8 = 65,
		LBF_BUFFER_READU8 = 66,
		LBF_BUFFER_WRITEU8 = 67,
		LBF_BUFFER_READI16 = 68,
		LBF_BUFFER_READU16 = 69,
		LBF_BUFFER_WRITEU16 = 70,
		LBF_BUFFER_READI32 = 71,
		LBF_BUFFER_READU32 = 72,
		LBF_BUFFER_WRITEU32 = 73,
		LBF_BUFFER_READF32 = 74,
		LBF_BUFFER_WRITEF32 = 75,
		LBF_BUFFER_READF64 = 76,
		LBF_BUFFER_WRITEF64 = 77,

		-- vector.
		LBF_VECTOR_MAGNITUDE = 78,
		LBF_VECTOR_NORMALIZE = 79,
		LBF_VECTOR_CROSS = 80,
		LBF_VECTOR_DOT = 81,
		LBF_VECTOR_FLOOR = 82,
		LBF_VECTOR_CEIL = 83,
		LBF_VECTOR_ABS = 84,
		LBF_VECTOR_SIGN = 85,
		LBF_VECTOR_CLAMP = 86,
		LBF_VECTOR_MIN = 87,
		LBF_VECTOR_MAX = 88
	},
	-- Proto flag bitmask, stored in Proto::flags
	ProtoFlag = {
		-- used to tag main proto for modules with --!native
		LPF_NATIVE_MODULE = bit32.lshift(1, 0),
		-- used to tag individual protos as not profitable to compile natively
		LPF_NATIVE_COLD = bit32.lshift(1, 1),
		-- used to tag main proto for modules that have at least one function with native attribute
		LPF_NATIVE_FUNCTION = bit32.lshift(1, 2)
	}
}

-- Bytecode instruction header: it's always a 32-bit integer, with low byte (first byte in little endian) containing the opcode
-- Some instruction types require more data and have more 32-bit integers following the header
function Luau:INSN_OP(insn)
	return bit32.band(insn, 0xFF)
end

-- ABC encoding: three 8-bit values, containing registers or small numbers
function Luau:INSN_A(insn)
	return bit32.band(bit32.rshift(insn, 8), 0xFF)
end
function Luau:INSN_B(insn)
	return bit32.band(bit32.rshift(insn, 16), 0xFF)
end
function Luau:INSN_C(insn)
	return bit32.band(bit32.rshift(insn, 24), 0xFF)
end

-- AD encoding: one 8-bit value, one signed 16-bit value
function Luau:INSN_D(insn) -- (0..32767)
	return bit32.rshift(insn, 16)
end
function Luau:INSN_sD(insn) -- (-32768..32767)
	local D = Luau:INSN_D(insn)
	local sD = D
	if D > 0x7FFF and D <= 0xFFFF then
		sD = (-(0xFFFF - D)) - 1
	end
	return sD
end

-- E encoding: one signed 24-bit value
function Luau:INSN_E(insn)
	return bit32.rshift(insn, 8)
end

-- Type to string for typeinfo
function Luau:GetBaseTypeString(type, checkOptional)
	local LuauBytecodeType = Luau.BytecodeType

	local tag = bit32.band(type, bit32.bnot(LuauBytecodeType.LBC_TYPE_OPTIONAL_BIT))

	local result

	if tag == LuauBytecodeType.LBC_TYPE_NIL then
		result = "nil"
	elseif tag == LuauBytecodeType.LBC_TYPE_BOOLEAN then
		result = "boolean"
	elseif tag == LuauBytecodeType.LBC_TYPE_NUMBER then
		result = "number"
	elseif tag == LuauBytecodeType.LBC_TYPE_STRING then
		result = "string"
	elseif tag == LuauBytecodeType.LBC_TYPE_TABLE then
		result = "table" -- not a valid type by itself
	elseif tag == LuauBytecodeType.LBC_TYPE_FUNCTION then
		result = "function" -- not a valid type by itself
	elseif tag == LuauBytecodeType.LBC_TYPE_THREAD then
		result = "thread"
	elseif tag == LuauBytecodeType.LBC_TYPE_USERDATA then
		result = "userdata" -- might be Instance
	elseif tag == LuauBytecodeType.LBC_TYPE_VECTOR then
		result = "Vector3"
	elseif tag == LuauBytecodeType.LBC_TYPE_BUFFER then
		result = "buffer"
	elseif tag == LuauBytecodeType.LBC_TYPE_ANY then
		result = "any"
	else
		error("Unhandled type in GetBaseTypeString", 2)
	end

	if checkOptional then
		local optional = bit32.band(type, LuauBytecodeType.LBC_TYPE_OPTIONAL_BIT) == 0 and "" or "?"
		result ..= optional
	end

	return result
end
-- Id provided by LOP_NAMECALL to function string representation
function Luau:GetBuiltinInfo(bfid)
	local LuauBuiltinFunction = Luau.BuiltinFunction

	if bfid == LuauBuiltinFunction.LBF_NONE then
		return "none"
	else
		if bfid == LuauBuiltinFunction.LBF_ASSERT then
			return "assert"
		elseif bfid == LuauBuiltinFunction.LBF_TYPE then
			return "type"
		elseif bfid == LuauBuiltinFunction.LBF_TYPEOF then
			return "typeof"
		elseif bfid == LuauBuiltinFunction.LBF_RAWSET then
			return "rawset"
		elseif bfid == LuauBuiltinFunction.LBF_RAWGET then
			return "rawget"
		elseif bfid == LuauBuiltinFunction.LBF_RAWEQUAL then
			return "rawequal"
		elseif bfid == LuauBuiltinFunction.LBF_RAWLEN then
			return "rawlen"
		elseif bfid == LuauBuiltinFunction.LBF_TABLE_UNPACK then
			return "unpack"
		elseif bfid == LuauBuiltinFunction.LBF_SELECT_VARARG then
			return "select"
		elseif bfid == LuauBuiltinFunction.LBF_GETMETATABLE then
			return "getmetatable"
		elseif bfid == LuauBuiltinFunction.LBF_SETMETATABLE then
			return "setmetatable"
		elseif bfid == LuauBuiltinFunction.LBF_TONUMBER then
			return "tonumber"
		elseif bfid == LuauBuiltinFunction.LBF_TOSTRING then
			return "tostring"
		end

		if bfid == LuauBuiltinFunction.LBF_MATH_ABS then
			return "math.abs"
		elseif bfid == LuauBuiltinFunction.LBF_MATH_ACOS then
			return "math.acos"
		elseif bfid == LuauBuiltinFunction.LBF_MATH_ASIN then
			return "math.asin"
		elseif bfid == LuauBuiltinFunction.LBF_MATH_ATAN2 then
			return "math.atan2"
		elseif bfid == LuauBuiltinFunction.LBF_MATH_ATAN then
			return "math.atan"
		elseif bfid == LuauBuiltinFunction.LBF_MATH_CEIL then
			return "math.ceil"
		elseif bfid == LuauBuiltinFunction.LBF_MATH_COSH then
			return "math.cosh"
		elseif bfid == LuauBuiltinFunction.LBF_MATH_COS then
			return "math.cos"
		elseif bfid == LuauBuiltinFunction.LBF_MATH_DEG then
			return "math.deg"
		elseif bfid == LuauBuiltinFunction.LBF_MATH_EXP then
			return "math.exp"
		elseif bfid == LuauBuiltinFunction.LBF_MATH_FLOOR then
			return "math.floor"
		elseif bfid == LuauBuiltinFunction.LBF_MATH_FMOD then
			return "math.fmod"
		elseif bfid == LuauBuiltinFunction.LBF_MATH_FREXP then
			return "math.frexp"
		elseif bfid == LuauBuiltinFunction.LBF_MATH_LDEXP then
			return "math.ldexp"
		elseif bfid == LuauBuiltinFunction.LBF_MATH_LOG10 then
			return "math.log10"
		elseif bfid == LuauBuiltinFunction.LBF_MATH_LOG then
			return "math.log"
		elseif bfid == LuauBuiltinFunction.LBF_MATH_MAX then
			return "math.max"
		elseif bfid == LuauBuiltinFunction.LBF_MATH_MIN then
			return "math.min"
		elseif bfid == LuauBuiltinFunction.LBF_MATH_MODF then
			return "math.modf"
		elseif bfid == LuauBuiltinFunction.LBF_MATH_POW then
			return "math.pow"
		elseif bfid == LuauBuiltinFunction.LBF_MATH_RAD then
			return "math.rad"
		elseif bfid == LuauBuiltinFunction.LBF_MATH_SINH then
			return "math.sinh"
		elseif bfid == LuauBuiltinFunction.LBF_MATH_SIN then
			return "math.sin"
		elseif bfid == LuauBuiltinFunction.LBF_MATH_SQRT then
			return "math.sqrt"
		elseif bfid == LuauBuiltinFunction.LBF_MATH_TANH then
			return "math.tanh"
		elseif bfid == LuauBuiltinFunction.LBF_MATH_TAN then
			return "math.tan"
		elseif bfid == LuauBuiltinFunction.LBF_MATH_CLAMP then
			return "math.clamp"
		elseif bfid == LuauBuiltinFunction.LBF_MATH_SIGN then
			return "math.sign"
		elseif bfid == LuauBuiltinFunction.LBF_MATH_ROUND then
			return "math.round"
		end

		if bfid == LuauBuiltinFunction.LBF_BIT32_ARSHIFT then
			return "bit32.arshift"
		elseif bfid == LuauBuiltinFunction.LBF_BIT32_BAND then
			return "bit32.band"
		elseif bfid == LuauBuiltinFunction.LBF_BIT32_BNOT then
			return "bit32.bnot"
		elseif bfid == LuauBuiltinFunction.LBF_BIT32_BOR then
			return "bit32.bor"
		elseif bfid == LuauBuiltinFunction.LBF_BIT32_BXOR then
			return "bit32.bxor"
		elseif bfid == LuauBuiltinFunction.LBF_BIT32_BTEST then
			return "bit32.btest"
		elseif bfid == LuauBuiltinFunction.LBF_BIT32_EXTRACT or bfid == LuauBuiltinFunction.LBF_BIT32_EXTRACTK then
			return "bit32.extract"
		elseif bfid == LuauBuiltinFunction.LBF_BIT32_LROTATE then
			return "bit32.lrotate"
		elseif bfid == LuauBuiltinFunction.LBF_BIT32_LSHIFT then
			return "bit32.lshift"
		elseif bfid == LuauBuiltinFunction.LBF_BIT32_REPLACE then
			return "bit32.replace"
		elseif bfid == LuauBuiltinFunction.LBF_BIT32_RROTATE then
			return "bit32.rrotate"
		elseif bfid == LuauBuiltinFunction.LBF_BIT32_RSHIFT then
			return "bit32.rshift"
		elseif bfid == LuauBuiltinFunction.LBF_BIT32_COUNTLZ then
			return "bit32.countlz"
		elseif bfid == LuauBuiltinFunction.LBF_BIT32_COUNTRZ then
			return "bit32.countrz"
		elseif bfid == LuauBuiltinFunction.LBF_BIT32_BYTESWAP then
			return "bit32.byteswap"
		end

		if bfid == LuauBuiltinFunction.LBF_STRING_BYTE then
			return "string.byte"
		elseif bfid == LuauBuiltinFunction.LBF_STRING_CHAR then
			return "string.char"
		elseif bfid == LuauBuiltinFunction.LBF_STRING_LEN then
			return "string.len"
		elseif bfid == LuauBuiltinFunction.LBF_STRING_SUB then
			return "string.sub"
		end

		if bfid == LuauBuiltinFunction.LBF_TABLE_INSERT then
			return "table.insert"
		end

		if bfid == LuauBuiltinFunction.LBF_VECTOR then
			return "Vector3.new"
		end

		if bfid == LuauBuiltinFunction.LBF_BUFFER_READI8 then
			return "buffer.readi8"
		elseif bfid == LuauBuiltinFunction.LBF_BUFFER_READU8 then
			return "buffer.readu8"
		elseif bfid == LuauBuiltinFunction.LBF_BUFFER_WRITEU8 then
			return "buffer.writeu8"
		elseif bfid == LuauBuiltinFunction.LBF_BUFFER_READI16 then
			return "buffer.readi16"
		elseif bfid == LuauBuiltinFunction.LBF_BUFFER_READU16 then
			return "buffer.readu16"
		elseif bfid == LuauBuiltinFunction.LBF_BUFFER_WRITEU16 then
			return "buffer.writeu16"
		elseif bfid == LuauBuiltinFunction.LBF_BUFFER_READI32 then
			return "buffer.readi32"
		elseif bfid == LuauBuiltinFunction.LBF_BUFFER_READU32 then
			return "buffer.readu32"
		elseif bfid == LuauBuiltinFunction.LBF_BUFFER_WRITEU32 then
			return "buffer.writeu32"
		elseif bfid == LuauBuiltinFunction.LBF_BUFFER_READF32 then
			return "buffer.readf32"
		elseif bfid == LuauBuiltinFunction.LBF_BUFFER_WRITEF32 then
			return "buffer.writef32"
		elseif bfid == LuauBuiltinFunction.LBF_BUFFER_READF64 then
			return "buffer.readf64"
		elseif bfid == LuauBuiltinFunction.LBF_BUFFER_WRITEF64 then
			return "buffer.writef64"
		end

		if bfid == LuauBuiltinFunction.LBF_VECTOR_MAGNITUDE then
			return "vector.magnitude"
		elseif bfid == LuauBuiltinFunction.LBF_VECTOR_NORMALIZE then
			return "vector.normalize"
		elseif bfid == LuauBuiltinFunction.LBF_VECTOR_CROSS then
			return "vector.cross"
		elseif bfid == LuauBuiltinFunction.LBF_VECTOR_DOT then
			return "vector.dot"
		elseif bfid == LuauBuiltinFunction.LBF_VECTOR_FLOOR then
			return "vector.floor"
		elseif bfid == LuauBuiltinFunction.LBF_VECTOR_CEIL then
			return "vector.ceil"
		elseif bfid == LuauBuiltinFunction.LBF_VECTOR_ABS then
			return "vector.abs"
		elseif bfid == LuauBuiltinFunction.LBF_VECTOR_SIGN then
			return "vector.sign"
		elseif bfid == LuauBuiltinFunction.LBF_VECTOR_CLAMP then
			return "vector.clamp"
		elseif bfid == LuauBuiltinFunction.LBF_VECTOR_MIN then
			return "vector.min"
		elseif bfid == LuauBuiltinFunction.LBF_VECTOR_MAX then
			return "vector.max"
		end
	end
end

-- finalize
local function prepare(t)
	local function reconstruct(original, fn)
		local new = {}
		for i, v in original do
			fn(new, i, v)
		end
		return new
	end

	local LuauOpCode = t.OpCode

	-- Assign opcodes their case number
	t.OpCode = reconstruct(LuauOpCode, function(self, i, v)
		local case = bit32.band((i - 1)*CASE_MULTIPLIER, 0xFF)
		self[case] = v
	end)

	return t
end

return prepare(Luau)
