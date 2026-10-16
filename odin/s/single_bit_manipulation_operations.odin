package single_bit_manipulation_operations

import "core:c"

@(export)
single_bit_manipulation_operations :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length != 3 do return -1
	opcode, number, position := input[0], input[1], input[2]
	if opcode < 0 || opcode > 5 || number < -2147483648 || number > 2147483647 do return -1
	if opcode == 5 {
		if position != -1 do return -1
		return number & (number - 1)
	}
	if position < 0 || position > 31 do return -1
	mask := i64(1) << u32(position)
	switch opcode {
	case 0: return number | mask
	case 1: return number & ~mask
	case 2: return number ^ mask
	case 3: return i64((transmute(u64)number >> u32(position)) & 1)
	case 4: if (number & mask) != 0 do return 1; return 0
	}
	return -1
}
