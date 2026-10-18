package hash_table

import "core:c"

TABLE_CAPACITY :: 17
MAX_INSERT_COUNT :: 8
MAX_QUERY_COUNT :: 8
MAX_KEY :: i64(1000)
MAX_PARSEABLE_LENGTH :: 19

store_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8((bits >> u64(byte * 8)) & 255)
	}
}

@(export)
hash_table :: proc "c" (values: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if values == nil || length < 2 || length > c.size_t(MAX_PARSEABLE_LENGTH) do return -1
	raw_insert_count := values[0]
	if raw_insert_count < 0 || raw_insert_count > MAX_INSERT_COUNT do return -1
	insert_count := int(raw_insert_count)
	query_count_index := 1 + insert_count
	if c.size_t(query_count_index) >= length do return -1
	raw_query_count := values[query_count_index]
	if raw_query_count < 1 || raw_query_count > MAX_QUERY_COUNT do return -1
	query_count := int(raw_query_count)
	query_start := query_count_index + 1
	total_keys := insert_count + query_count
	if length != c.size_t(query_start + query_count) do return -1

	for index := 0; index < total_keys; index += 1 {
		position := if index < insert_count { 1 + index } else { query_start + index - insert_count }
		key := values[position]
		if key < 1 || key > MAX_KEY do return -1
		for prior := 0; prior < index; prior += 1 {
			prior_position := if prior < insert_count { 1 + prior } else { query_start + prior - insert_count }
			other := values[prior_position]
			same_group := (index < insert_count) == (prior < insert_count)
			if key == other {
				if same_group do return -1
			} else if key % TABLE_CAPACITY == other % TABLE_CAPACITY || key % 3000 == other % 3000 {
				return -1
			}
		}
	}

	table: [TABLE_CAPACITY]i64
	for index := 0; index < TABLE_CAPACITY; index += 1 do table[index] = 0
	for index := 0; index < insert_count; index += 1 {
		key := values[1 + index]
		table[int(key % TABLE_CAPACITY)] = key
	}

	output_bytes := 8 * query_count
	if output == nil || output_capacity < c.size_t(output_bytes) do return -2
	for index := 0; index < query_count; index += 1 {
		query := values[query_start + index]
		found := i64(0)
		if table[int(query % TABLE_CAPACITY)] == query do found = 1
		store_i64_le(output, 8 * index, found)
	}
	return i64(output_bytes)
}
