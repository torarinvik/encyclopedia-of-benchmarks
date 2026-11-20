package stormer_verlet_position

import "core:c"

MAX_STEPS :: 32
MAX_INPUT_VALUES :: MAX_STEPS + 1
MAX_OUTPUT_BYTES :: MAX_STEPS * 8

store_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := transmute(u64)value
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8((bits >> (8 * byte)) & 255)
	}
}

@(export)
stormer_verlet_position :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > MAX_INPUT_VALUES do return -1
	count_value := input[0]
	if count_value < 2 || count_value > MAX_STEPS do return -1
	if length != c.size_t(count_value + 1) do return -1
	if input[1] < -1024 || input[1] > 1024 || input[2] < -1024 || input[2] > 1024 do return -1
	count := int(count_value)
	for step := 0; step < count-2; step += 1 {
		if input[3+step] < -64 || input[3+step] > 64 do return -1
	}

	byte_count := c.size_t(8 * count)
	if output == nil || output_capacity < byte_count do return -2
	var staged: [MAX_OUTPUT_BYTES]u8
	previous, current := input[1], input[2]
	store_i64_le(&staged[0], 0, previous)
	store_i64_le(&staged[0], 8, current)
	for index := 2; index < count; index += 1 {
		next := 2*current - previous + input[index+1]
		store_i64_le(&staged[0], 8*index, next)
		previous, current = current, next
	}
	for byte: c.size_t = 0; byte < byte_count; byte += 1 { output[byte] = staged[byte] }
	return i64(byte_count)
}
