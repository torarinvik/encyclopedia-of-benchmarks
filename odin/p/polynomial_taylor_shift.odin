package polynomial_taylor_shift

import "core:c"

MODULUS :: i64(998244353)
MAX_N :: 64
MAX_INPUT :: 66
Shifted :: [MAX_N]i64

store_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8(bits & 255)
		bits >>= 8
	}
}

@(export)
polynomial_taylor_shift :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > MAX_INPUT do return -1
	if input[0] < 1 || input[0] > MAX_N do return -1
	n := int(input[0])
	shift := input[1]
	if int(length) != n + 2 || shift < 0 || shift >= MODULUS do return -1
	for i := 0; i < n; i += 1 {
		if input[i + 2] < 0 || input[i + 2] >= MODULUS do return -1
	}
	bytes := 8 * n
	if output == nil || int(capacity) < bytes do return -2
	shifted := Shifted{}
	processed := 0
	for source := n; source > 0; source -= 1 {
		for degree := processed; degree > 0; degree -= 1 {
			shifted[degree] = (shifted[degree] * shift + shifted[degree - 1]) % MODULUS
		}
		shifted[0] = (shifted[0] * shift + input[source + 1]) % MODULUS
		processed += 1
	}
	for i := 0; i < n; i += 1 { store_le(output, 8 * i, shifted[i]) }
	return i64(bytes)
}
