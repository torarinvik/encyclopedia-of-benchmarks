package farey_sequence_ordered_enumeration

import "core:c"

farey_count :: proc "contextless" (order: i64) -> i64 {
	a, b, c_value, d := i64(0), i64(1), i64(1), order
	count := i64(1)
	for {
		count += 1
		if c_value == d do break
		k := (order + b) / d
		next_c := k * c_value - a
		next_d := k * d - b
		a, b, c_value, d = c_value, d, next_c, next_d
	}
	return count
}

store_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8((bits >> u64(byte * 8)) & 255)
	}
}

@(export)
farey_sequence_ordered_enumeration :: proc "c" (values: [^]i64, length: c.size_t,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	if values == nil || length != 1 do return -1
	order := values[0]
	if order < 1 || order > 32 do return -1
	count := farey_count(order)
	required := (1 + 2 * count) * 8
	if output == nil || output_capacity < c.size_t(required) do return -2

	store_i64_le(output, 0, count)
	store_i64_le(output, 8, 0)
	store_i64_le(output, 16, 1)
	a, b, c_value, d := i64(0), i64(1), i64(1), order
	position := 24
	for {
		store_i64_le(output, position, c_value)
		store_i64_le(output, position + 8, d)
		position += 16
		if c_value == d do break
		k := (order + b) / d
		next_c := k * c_value - a
		next_d := k * d - b
		a, b, c_value, d = c_value, d, next_c, next_d
	}
	return required
}
