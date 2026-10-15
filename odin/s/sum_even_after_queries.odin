package sum_even_after_queries

import "core:c"

MAX_NUMBERS :: 1000
MAX_QUERIES :: 1000

// Apply updates in order and emit the running even sum as little-endian i32s.
@(export)
sum_even_after_queries :: proc "c" (values: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if length < 5 || length > 4002 || values == nil do return -1
	if values[0] < 1 || values[0] > MAX_NUMBERS || values[1] < 1 || values[1] > MAX_QUERIES do return -1
	number_count := c.size_t(values[0])
	query_count := c.size_t(values[1])
	if length != 2 + number_count + 2 * query_count do return -1

	working: [MAX_NUMBERS]i64
	even_sum := i64(0)
	for index := c.size_t(0); index < number_count; index += 1 {
		value := values[2 + index]
		if value < 1 || value > 1000 do return -1
		working[index] = value
		if value % 2 == 0 do even_sum += value
	}
	for query := c.size_t(0); query < query_count; query += 1 {
		offset := 2 + number_count + 2 * query
		invalid_delta := values[offset] < -1000 || values[offset] > 1000
		invalid_index := values[offset + 1] < 0 || values[offset + 1] >= i64(number_count)
		if invalid_delta || invalid_index do return -1
	}
	output_bytes := query_count * 4
	if output_capacity < output_bytes || output == nil do return -2

	for query := c.size_t(0); query < query_count; query += 1 {
		offset := 2 + number_count + 2 * query
		delta := values[offset]
		index := c.size_t(values[offset + 1])
		if working[index] % 2 == 0 do even_sum -= working[index]
		working[index] += delta
		if working[index] % 2 == 0 do even_sum += working[index]
		bits := u32(i32(even_sum))
		for byte := 0; byte < 4; byte += 1 {
			output[query * 4 + c.size_t(byte)] = u8((bits >> u32(byte * 8)) & 255)
		}
	}
	return i64(query_count)
}
