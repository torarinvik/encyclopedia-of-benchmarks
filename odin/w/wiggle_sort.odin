package wiggle_sort

import "core:c"

MAX_ARRAY_LENGTH :: 4096

store_i32_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u32(i32(value))
	for byte := 0; byte < 4; byte += 1 {
		output[offset + byte] = u8((bits >> u32(byte * 8)) & 255)
	}
}

@(export)
wiggle_sort :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	if length > c.size_t(MAX_ARRAY_LENGTH) || (length != 0 && input == nil) do return -1
	if output_capacity < length * 4 || (length != 0 && output == nil) do return -2
	values: [MAX_ARRAY_LENGTH]i64
	for index := 0; index < int(length); index += 1 {
		value := input[index]
		if value < -2_147_483_648 || value > 2_147_483_647 do return -1
		values[index] = value
	}
	for index := 1; index < int(length); index += 1 {
		if (index % 2 == 1 && values[index - 1] > values[index]) || (index % 2 == 0 && values[index - 1] < values[index]) {
			temporary := values[index]
			values[index] = values[index - 1]
			values[index - 1] = temporary
		}
	}
	if output_capacity < length * 4 do return -2
	for index := 0; index < int(length); index += 1 {
		store_i32_le(output, index * 4, values[index])
	}
	return i64(length)
}
