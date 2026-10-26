package prolangs_c_simulator_shiftr

import "core:c"

// (c) William Landi 1991. Permission to use this code is granted as long as the copyright notice remains in place.
@(export)
prolangs_c_simulator_shiftr :: proc "c" (v: [^]i64, n: c.size_t) -> i64 {
	if v == nil || n != 2 do return -1
	operand, raw := v[0], v[1]
	if operand < 0 || operand > 255 || raw < 0 || raw > 0xFFFFFF || (operand >> 4) >= 10 do return -1
	shift := u32((operand & 15) + 1)
	value := u32(raw)
	result := value >> shift
	if (value & 0x800000) != 0 do result |= ((1 << shift) - 1) << (24 - shift)
	return i64(result & 0xFFFFFF)
}
