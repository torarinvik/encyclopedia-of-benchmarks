package get_products_of_all_other_elements

import "core:c"

MAX_ARRAY_LENGTH :: 32
MAX_INPUT_LENGTH :: c.size_t = 34

write_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := transmute(u64)value
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8(bits >> u64(8 * byte))
	}
}

@(export)
get_products_of_all_other_elements :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > MAX_INPUT_LENGTH do return -1
	if input[0] < 0 || input[0] > MAX_ARRAY_LENGTH do return -1
	n := int(input[0])
	if int(length) != n + 1 do return -1
	result: [MAX_ARRAY_LENGTH]i64 = {}
	for i := 0; i < n; i += 1 {
		if input[i + 1] < -2 || input[i + 1] > 2 do return -1
	}
	if n < 2 do return 0
	output_bytes := c.size_t(n * 8)
	if output == nil || capacity < output_bytes do return -2

	result[0] = 1
	for i := 0; i < n - 1; i += 1 do result[i + 1] = input[i + 1] * result[i]
	suffix: i64 = 1
	for i := n - 1; i > 0; i -= 1 {
		value := input[i + 1]
		result[i - 1] *= suffix * value
		suffix *= value
	}
	for i := 0; i < n; i += 1 do write_i64_le(output, i * 8, result[i])
	return i64(output_bytes)
}
