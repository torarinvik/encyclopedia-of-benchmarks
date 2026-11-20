package american_flag_string_sorter

import "core:c"

@(export)
american_flag_string_sorter :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 || length > 8450 do return -1
	item_count_value := input[0]
	if item_count_value < 0 || item_count_value > 256 do return -1
	item_count := int(item_count_value)

	string_lengths: [256]int
	string_bytes: [8192]int
	indices: [256]int
	input_position := 1
	for string_index := 0; string_index < item_count; string_index += 1 {
		if input_position >= int(length) do return -1
		string_length_value := input[input_position]
		if string_length_value < 0 || string_length_value > 32 do return -1
		string_length := int(string_length_value)
		input_position += 1
		if input_position + string_length > int(length) do return -1
		string_lengths[string_index] = string_length
		indices[string_index] = string_index
		for byte_index := 0; byte_index < string_length; byte_index += 1 {
			byte_value := input[input_position + byte_index]
			if byte_value < 0 || byte_value > 255 do return -1
			string_bytes[string_index * 32 + byte_index] = int(byte_value)
		}
		input_position += string_length
	}
	if input_position != int(length) do return -1

	stack_low: [512]int
	stack_high: [512]int
	stack_depth: [512]int
	stack_size := 1
	stack_low[0] = 0
	stack_high[0] = item_count
	stack_depth[0] = 0

	for stack_size > 0 {
		stack_size -= 1
		low := stack_low[stack_size]
		high := stack_high[stack_size]
		depth := stack_depth[stack_size]
		if high - low <= 1 || depth >= 32 do continue

		counts: [257]int
		for bucket := 0; bucket < 257; bucket += 1 { counts[bucket] = 0 }
		starts: [258]int
		next: [257]int
		for position := low; position < high; position += 1 {
			string_index := indices[position]
			key := 0
			if depth < string_lengths[string_index] {
				key = string_bytes[string_index * 32 + depth] + 1
			}
			counts[key] += 1
		}

		starts[0] = low
		for bucket := 0; bucket < 257; bucket += 1 {
			starts[bucket + 1] = starts[bucket] + counts[bucket]
			next[bucket] = starts[bucket]
		}

		for bucket := 0; bucket < 257; bucket += 1 {
			for next[bucket] < starts[bucket + 1] {
				position := next[bucket]
				string_index := indices[position]
				key := 0
				if depth < string_lengths[string_index] {
					key = string_bytes[string_index * 32 + depth] + 1
				}
				if key == bucket {
					next[bucket] += 1
				} else {
					destination := next[key]
					displaced := indices[destination]
					indices[destination] = string_index
					indices[position] = displaced
					next[key] += 1
				}
			}
		}

		bucket := 256
		for bucket > 0 {
			if counts[bucket] > 1 {
				stack_low[stack_size] = starts[bucket]
				stack_high[stack_size] = starts[bucket + 1]
				stack_depth[stack_size] = depth + 1
				stack_size += 1
			}
			bucket -= 1
		}
	}

	checksum: i64 = 0
	for rank := 0; rank < item_count; rank += 1 {
		string_index := indices[rank]
		string_length := string_lengths[string_index]
		contribution := i64(string_length + 1)
		for byte_index := 0; byte_index < string_length; byte_index += 1 {
			contribution += i64(string_bytes[string_index * 32 + byte_index] + 1)
		}
		checksum += i64(rank + 1) * contribution
	}
	return checksum
}
