package circle_line_intersection_count

import "core:c"

MAX_Q :: 32
MAX_OUTPUT_BYTES :: 8 * MAX_Q

write_i64 :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := transmute(u64)value
	for byte := 0; byte < 8; byte += 1 do output[offset + byte] = u8(bits >> (8 * byte))
}

@(export)
circle_line_intersection_count :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 4 || length > 101 do return -1
	center_x, center_y, radius, query_value := input[0], input[1], input[2], input[3]
	if center_x < -1000 || center_x > 1000 || center_y < -1000 || center_y > 1000 ||
		radius < 0 || radius > 1000 || query_value < 0 || query_value > MAX_Q do return -1
	query_count := int(query_value)
	if int(length) != 4 + 3 * query_count do return -1
	a_values: [MAX_Q]i64 = {}
	b_values: [MAX_Q]i64 = {}
	c_values: [MAX_Q]i64 = {}
	for query := 0; query < query_count; query += 1 {
		a, b, c_value := input[4 + 3 * query], input[5 + 3 * query], input[6 + 3 * query]
		if a < -100 || a > 100 || b < -100 || b > 100 || (a == 0 && b == 0) ||
			c_value < -200000 || c_value > 200000 do return -1
		a_values[query], b_values[query], c_values[query] = a, b, c_value
	}
	needed := 8 * query_count
	if needed > 0 && (output == nil || int(capacity) < needed) do return -2
	staged: [MAX_OUTPUT_BYTES]u8 = {}
	for query := 0; query < query_count; query += 1 {
		a, b, c_value := a_values[query], b_values[query], c_values[query]
		offset := a * center_x + b * center_y + c_value
		normal_squared := a * a + b * b
		discriminant := radius * radius * normal_squared - offset * offset
		count := i64(0)
		if discriminant > 0 { count = 2 } else if discriminant == 0 { count = 1 }
		write_i64(&staged[0], 8 * query, count)
	}
	for byte := 0; byte < needed; byte += 1 do output[byte] = staged[byte]
	return i64(needed)
}
