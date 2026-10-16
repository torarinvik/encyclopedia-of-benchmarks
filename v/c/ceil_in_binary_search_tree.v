module main

const max_node_count = 127
const max_input_length = 3 + 3 * max_node_count
const value_min = -1_000_000
const value_max = 1_000_000

@[export: 'ceil_in_binary_search_tree']
pub fn ceil_in_binary_search_tree(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > max_input_length { return i64(-9223372036854775807) }
		node_count_value := input[0]
		root_index_value := input[1]
		key := input[2]
		if node_count_value < 0 || node_count_value > max_node_count || key < value_min || key > value_max { return i64(-9223372036854775807) }
		node_count := int(node_count_value)
		if int(length) != 3 + 3 * node_count { return i64(-9223372036854775807) }
		if node_count == 0 {
			if root_index_value == -1 { return i64(-9223372036854775807) - 1 }
			return i64(-9223372036854775807)
		}
		if root_index_value < 0 || root_index_value >= node_count_value { return i64(-9223372036854775807) }

		mut current := int(root_index_value)
		mut best := i64(-9223372036854775807) - 1
		mut steps := 0
		for current >= 0 {
			if steps >= node_count { return i64(-9223372036854775807) }
			offset := 3 + 3 * current
			value := input[offset]
			left := input[offset + 1]
			right := input[offset + 2]
			if value < value_min || value > value_max || left < -1 || right < -1 || left >= node_count_value || right >= node_count_value { return i64(-9223372036854775807) }
			if value == key { return value }
			if value < key { current = int(right) }
			else { best = value; current = int(left) }
			steps++
		}
		return best
	}
}
