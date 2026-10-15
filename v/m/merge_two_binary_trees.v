module merge_two_binary_trees

const max_tree_slots = 255
const max_input_length = 512
const null_slot = i64(-1_000_001)

fn valid_tree(input &i64, start usize, count usize) bool {
	unsafe {
		for index in 0 .. count {
			value := input[start + index]
			if value != null_slot && (value < -100_000 || value > 100_000) { return false }
			if index > 0 && input[start + (index - 1) / 2] == null_slot && value != null_slot { return false }
		}
	}
	return true
}

@[export: 'merge_two_binary_trees']
pub fn merge_two_binary_trees(input &i64, length usize, output &u8, output_capacity usize) i64 {
	if length < 2 || length > max_input_length { return -1 }
	unsafe {
		if input[0] < 0 || input[0] > max_tree_slots { return -1 }
		first_count := usize(input[0])
		second_count_position := first_count + 1
		if second_count_position >= length { return -1 }
		if input[second_count_position] < 0 || input[second_count_position] > max_tree_slots { return -1 }
		second_count := usize(input[second_count_position])
		first_start := usize(1)
		second_start := second_count_position + 1
		if length != second_start + second_count { return -1 }
		if !valid_tree(input, first_start, first_count) || !valid_tree(input, second_start, second_count) { return -1 }

		maximum_slots := if first_count > second_count { first_count } else { second_count }
		mut merged := [max_tree_slots]i32{init: 0}
		mut node_count := i64(0)
		for index in 0 .. maximum_slots {
			first := if index < first_count { input[first_start + index] } else { null_slot }
			second := if index < second_count { input[second_start + index] } else { null_slot }
			if first == null_slot && second == null_slot {
				merged[index] = i32(null_slot)
			} else {
				first_value := if first == null_slot { i64(0) } else { first }
				second_value := if second == null_slot { i64(0) } else { second }
				merged[index] = i32(first_value + second_value)
				node_count++
			}
		}
		mut output_slots := maximum_slots
		for output_slots > 0 && merged[output_slots - 1] == i32(null_slot) { output_slots-- }
		output_bytes := output_slots * 4
		if output_capacity < output_bytes || (output_bytes != 0 && output == nil) { return -2 }
		for index in 0 .. output_slots {
			bits := u32(merged[index])
			for byte in 0 .. 4 { output[index * 4 + byte] = u8((bits >> u32(byte * 8)) & 255) }
		}
		return node_count
	}
}
