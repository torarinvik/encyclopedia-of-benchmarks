package bag

import "core:c"

MAX_INSERTS :: 128
MAX_QUERIES :: 64

put_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8((bits >> u64(byte * 8)) & 255)
	}
}

@(export)
bag :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8,
		capacity: c.size_t) -> i64 {
	if input == nil || length < 2 { return -1 }
	insert_count_value := input[0]
	if insert_count_value < 0 || insert_count_value > MAX_INSERTS { return -1 }
	insert_count := int(insert_count_value)
	if length < c.size_t(insert_count + 2) { return -1 }
	query_count_value := input[insert_count + 1]
	if query_count_value < 0 || query_count_value > MAX_QUERIES { return -1 }
	query_count := int(query_count_value)
	if length != c.size_t(insert_count + query_count + 2) { return -1 }

	for index := 0; index < insert_count; index += 1 {
		if input[index + 1] < -2147483648 || input[index + 1] > 2147483647 { return -1 }
	}
	for query := 0; query < query_count; query += 1 {
		value := input[insert_count + query + 2]
		if value < -2147483648 || value > 2147483647 { return -1 }
	}
	output_length := (query_count + 2) * 8
	if output == nil || capacity < c.size_t(output_length) { return -2 }

	values: [128]i64
	distinct_count := 0
	for index := 0; index < insert_count; index += 1 {
		value := input[index + 1]
		node := 0
		for node < distinct_count && values[node] != value { node += 1 }
		if node == distinct_count {
			values[node] = value
			distinct_count += 1
		}
	}

	put_i64_le(output, 0, insert_count_value)
	is_empty := i64(0)
	if insert_count == 0 { is_empty = 1 }
	put_i64_le(output, 8, is_empty)
	for query := 0; query < query_count; query += 1 {
		target := input[insert_count + query + 2]
		contains: i64 = 0
		for node := 0; node < distinct_count; node += 1 {
			if values[node] == target { contains = 1 }
		}
		put_i64_le(output, (query + 2) * 8, contains)
	}
	return i64(output_length)
}
