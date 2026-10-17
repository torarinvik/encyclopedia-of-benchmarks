module prefix_aggregate_list

const max_initial_values = 64
const max_operations = 64
const max_live_values = 128
const max_parseable_input_length = 260
const max_output_bytes = 512
const max_value = i64(1_000_000)

fn store_i64_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'prefix_aggregate_list']
pub fn prefix_aggregate_list(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if length < 3 || length > max_parseable_input_length { return -1 }
	unsafe {
		if input == nil { return -1 }
		initial_count_value := input[0]
		if initial_count_value < 1 || initial_count_value > max_initial_values { return -1 }
		initial_count := int(initial_count_value)
		if int(length) < initial_count + 2 { return -1 }

		mut prefix := [max_live_values]i64{}
		for index in 0 .. initial_count {
			value := input[1 + index]
			if value < -max_value || value > max_value { return -1 }
			prefix[index] = value + if index == 0 { 0 } else { prefix[index - 1] }
		}

		operation_count_value := input[1 + initial_count]
		if operation_count_value < 0 || operation_count_value > max_operations { return -1 }
		operation_count := int(operation_count_value)
		mut live_count := initial_count
		mut cursor := initial_count + 2
		mut query_count := 0
		mut encoded := [max_output_bytes]u8{}

		for _ in 0 .. operation_count {
			if cursor >= int(length) { return -1 }
			operation := input[cursor]
			cursor++
			if operation == 0 {
				if cursor >= int(length) || live_count >= max_live_values { return -1 }
				value := input[cursor]
				cursor++
				if value < -max_value || value > max_value { return -1 }
				prefix[live_count] = prefix[live_count - 1] + value
				live_count++
			} else if operation == 1 {
				if live_count <= 1 { return -1 }
				live_count--
			} else if operation == 2 {
				if cursor + 1 >= int(length) { return -1 }
				range_from := input[cursor]
				range_to := input[cursor + 1]
				cursor += 2
				if range_from < 1 || range_to < range_from || range_to > i64(live_count) { return -1 }
				from_index := int(range_from)
				to_index := int(range_to)
				result := prefix[to_index - 1] - if from_index == 1 { 0 } else { prefix[from_index - 2] }
				store_i64_le(mut encoded, 8 * query_count, result)
				query_count++
			} else {
				return -1
			}
		}

		if cursor != int(length) { return -1 }
		output_bytes := 8 * query_count
		if output == nil || capacity < usize(output_bytes) { return -2 }
		for index in 0 .. output_bytes { output[index] = encoded[index] }
		return i64(output_bytes)
	}
}
