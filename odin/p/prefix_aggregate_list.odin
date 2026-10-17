package prefix_aggregate_list

import "core:c"

MAX_INITIAL_VALUES :: 64
MAX_OPERATIONS :: 64
MAX_LIVE_VALUES :: 128
MAX_INPUT_LENGTH :: 258
MAX_PARSEABLE_INPUT_LENGTH :: 260
MAX_OUTPUT_BYTES :: 512
MAX_VALUE :: i64(1_000_000)

@(export, link_name="prefix_aggregate_list")
prefix_aggregate_list :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > c.size_t(MAX_PARSEABLE_INPUT_LENGTH) do return -1
	initial_count_value := input[0]
	if initial_count_value < 1 || initial_count_value > MAX_INITIAL_VALUES do return -1
	initial_count := int(initial_count_value)
	if length < c.size_t(initial_count + 2) do return -1

	var prefix: [MAX_LIVE_VALUES]i64
	for index := 0; index < initial_count; index += 1 {
		value := input[1 + index]
		if value < -MAX_VALUE || value > MAX_VALUE do return -1
		prefix[index] = value
		if index > 0 do prefix[index] += prefix[index - 1]
	}

	operation_count_value := input[1 + initial_count]
	if operation_count_value < 0 || operation_count_value > MAX_OPERATIONS do return -1
	operation_count := int(operation_count_value)
	live_count := initial_count
	cursor := initial_count + 2
	query_count := 0
	var encoded: [MAX_OUTPUT_BYTES]u8

	for operation_index := 0; operation_index < operation_count; operation_index += 1 {
		if c.size_t(cursor) >= length do return -1
		operation := input[cursor]
		cursor += 1
		if operation == 0 {
			if c.size_t(cursor) >= length || live_count >= MAX_LIVE_VALUES do return -1
			value := input[cursor]
			cursor += 1
			if value < -MAX_VALUE || value > MAX_VALUE do return -1
			prefix[live_count] = prefix[live_count - 1] + value
			live_count += 1
		} else if operation == 1 {
			if live_count <= 1 do return -1
			live_count -= 1
		} else if operation == 2 {
			if c.size_t(cursor + 1) >= length do return -1
			range_from := input[cursor]
			range_to := input[cursor + 1]
			cursor += 2
			if range_from < 1 || range_to < range_from || range_to > i64(live_count) do return -1
			from_index := int(range_from)
			to_index := int(range_to)
			query_result := prefix[to_index - 1]
			if from_index > 1 do query_result -= prefix[from_index - 2]
			bits := u64(query_result)
			for byte := 0; byte < 8; byte += 1 {
				encoded[8 * query_count + byte] = u8(bits & 255)
				bits >>= 8
			}
			query_count += 1
		} else {
			return -1
		}
	}

	if c.size_t(cursor) != length do return -1
	output_bytes := 8 * query_count
	if output == nil || capacity < c.size_t(output_bytes) do return -2
	for index := 0; index < output_bytes; index += 1 { output[index] = encoded[index] }
	return i64(output_bytes)
}
