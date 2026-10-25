package tsvc_s252_adjacent_product_pair_sum

import "core:c"

// Clean-room bounded port of TSVC s252; see package README for provenance.
MAX_N :: 64

store_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte in 0 ..< 8 {
		output[offset + byte] = u8(bits & 0xff)
		bits >>= 8
	}
}

@(export)
tsvc_s252_adjacent_product_pair_sum :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > 129 do return -1
	if input[0] < 1 || input[0] > MAX_N do return -1
	n := int(input[0])
	if length != c.size_t(1 + 2 * n) do return -1
	var b, c: [MAX_N]i64
	for i := 0; i < n; i += 1 {
		b[i] = input[1 + i]
		c[i] = input[1 + n + i]
		if b[i] < -2 || b[i] > 2 || c[i] < -2 || c[i] > 2 do return -1
	}
	if output == nil || capacity < c.size_t(8 * n) do return -2
	previous_product := i64(0)
	for i := 0; i < n; i += 1 {
		product := b[i] * c[i]
		store_i64_le(output, 8 * i, product + previous_product)
		previous_product = product
	}
	return i64(n)
}
