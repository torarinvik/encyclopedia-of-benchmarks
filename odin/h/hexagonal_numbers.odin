package hexagonal_numbers

import "core:c"

MAX_LENGTH :: 1024
BYTES_PER_VALUE :: 8

store_i64_le :: proc "contextless" (output: [^]u8, position: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < BYTES_PER_VALUE; byte += 1 {
		output[position + byte] = u8((bits >> u64(byte * 8)) & 255)
	}
}

@(export)
hexagonal_numbers :: proc "c" (length: i64, output: [^]u8,
		output_capacity: c.size_t) -> i64 {
	if length < 1 || length > MAX_LENGTH do return -1
	n := int(length)
	required := c.size_t(n * BYTES_PER_VALUE)
	if output == nil || output_capacity < required do return -2
	for index := 0; index < n; index += 1 {
		i := i64(index)
		store_i64_le(output, index * BYTES_PER_VALUE, i * (2 * i - 1))
	}
	return length
}
