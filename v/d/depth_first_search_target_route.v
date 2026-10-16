module depth_first_search_target_route

const max_nodes = 64
const max_edges = 94
const max_input_length = 4 + max_nodes + 2 * max_edges
const max_output_bytes = 128

@[export: 'depth_first_search_target_route']
pub fn depth_first_search_target_route(values &i64, length usize, output &u8, output_capacity usize) i64 {
	if unsafe { values == nil } || length < 5 || length > max_input_length { return -2 }
	unsafe {
		if values[0] < 1 || values[0] > max_nodes || values[1] < 0 || values[1] > 255 || values[2] < 0 || values[2] > 255 { return -2 }
		node_count := int(values[0])
		start_label, target_label := values[1], values[2]
		edge_count_position := 3 + node_count
		if edge_count_position >= int(length) { return -2 }

		mut labels := [64]i64{init: 0}
		mut start_index := node_count
		for index in 0 .. node_count {
			label := values[3 + index]
			if label < 0 || label > 255 { return -2 }
			for prior in 0 .. index {
				if labels[prior] == label { return -2 }
			}
			labels[index] = label
			if label == start_label { start_index = index }
		}
		if start_index == node_count { return -2 }

		edge_count_value := values[edge_count_position]
		if edge_count_value < 0 || edge_count_value > max_edges { return -2 }
		edge_count := int(edge_count_value)
		if int(length) != edge_count_position + 1 + 2 * edge_count { return -2 }

		mut adjacency := [64]u64{init: 0}
		for edge in 0 .. edge_count {
			left_label := values[edge_count_position + 1 + 2 * edge]
			right_label := values[edge_count_position + 2 + 2 * edge]
			mut left := node_count
			mut right := node_count
			for index in 0 .. node_count {
				if labels[index] == left_label { left = index }
				if labels[index] == right_label { right = index }
			}
			if left == node_count || right == node_count { return -2 }
			adjacency[left] |= u64(1) << u64(right)
			adjacency[right] |= u64(1) << u64(left)
		}

		mut stack := [64]int{init: 0}
		mut stack_length := 1
		stack[0] = start_index
		mut route := [128]u8{init: 0}
		mut route_length := 0
		for stack_length != 0 {
			stack_length--
			current := stack[stack_length]
			if route_length == max_output_bytes { return -2 }
			route[route_length] = u8(labels[current])
			route_length++
			for neighbor in 0 .. node_count {
				bit := u64(1) << u64(neighbor)
				if adjacency[current] & bit != 0 {
					mut pending := 0
					for pending < stack_length && stack[pending] != neighbor { pending++ }
					if pending == stack_length {
						stack[stack_length] = neighbor
						stack_length++
					}
				}
				adjacency[current] &= ~bit
				adjacency[neighbor] &= ~(u64(1) << u64(current))
			}
			if labels[current] == target_label {
				if output_capacity < usize(route_length) || (route_length != 0 && output == nil) { return -2 }
				for index in 0 .. route_length { output[index] = route[index] }
				return i64(route_length)
			}
		}
		return 0
	}
}
