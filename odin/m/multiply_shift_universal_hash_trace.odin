package multiply_shift_universal_hash_trace

import "core:c"

@(export)
multiply_shift_universal_hash_trace :: proc "c" (
	input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t,
) -> i64 {
	max_queries := 32
	word_mask: u64 = 0xffff_ffff
	if input == nil || length < 2 || length > 67 do return -1
	width := input[0]
	count_value := input[1]
	if width < 1 || width > 16 || count_value < 0 || count_value > max_queries do return -1
	count := int(count_value)
	if length != c.size_t(2 + 2 * count) do return -1

	for query := 0; query < count; query += 1 {
		multiplier := input[2 + 2 * query]
		key := input[3 + 2 * query]
		if multiplier < 1 || multiplier > 4294967295 || (multiplier & 1) == 0 do return -1
		if key < 0 || key > 4294967295 do return -1
	}

	required := count * 8
	if (required > 0 && output == nil) || capacity < c.size_t(required) do return -2
	shift := 32 - int(width)
	for query := 0; query < count; query += 1 {
		multiplier := u64(input[2 + 2 * query])
		key := u64(input[3 + 2 * query])
		low_word := (multiplier * key) & word_mask
		value := low_word >> shift
		for byte := 0; byte < 8; byte += 1 {
			output[query * 8 + byte] = u8(value >> (8 * byte))
		}
	}
	return i64(required)
}
