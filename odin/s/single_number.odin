package single_number

import "core:c"

// XOR reduction for the signed 32-bit single-number contract.
@(export)
single_number :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if length == 0 || length > 257 do return -2_147_483_649
	bits := i64(0)
	for i: c.size_t = 0; i < length; i += 1 {
		value := values[i]
		if value < -2_147_483_648 || value > 2_147_483_647 do return -2_147_483_649
		word := value
		if word < 0 do word += 4_294_967_296
		bits = bits ~ word
	}
	if bits > 2_147_483_647 do return bits - 4_294_967_296
	return bits
}
