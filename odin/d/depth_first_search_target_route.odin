package depth_first_search_target_route

import "core:c"

MAX_NODES :: 64
MAX_EDGES :: 94
MAX_INPUT_LENGTH :: 4 + MAX_NODES + 2 * MAX_EDGES
MAX_OUTPUT_BYTES :: 128

@(export)
depth_first_search_target_route :: proc "c" (values: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if values == nil || length < 5 || length > MAX_INPUT_LENGTH do return -2
	if values[0] < 1 || values[0] > MAX_NODES || values[1] < 0 || values[1] > 255 || values[2] < 0 || values[2] > 255 do return -2
	node_count := usize(values[0])
	start_label, target_label := values[1], values[2]
	edge_count_position := 3 + node_count
	if edge_count_position >= length do return -2

	labels: [MAX_NODES]i64 = {}
	start_index := node_count
	for index: usize = 0; index < node_count; index += 1 {
		label := values[3 + index]
		if label < 0 || label > 255 do return -2
		for prior: usize = 0; prior < index; prior += 1 {
			if labels[prior] == label do return -2
		}
		labels[index] = label
		if label == start_label do start_index = index
	}
	if start_index == node_count do return -2

	edge_count_value := values[edge_count_position]
	if edge_count_value < 0 || edge_count_value > MAX_EDGES do return -2
	edge_count := usize(edge_count_value)
	if length != c.size_t(edge_count_position + 1 + 2 * edge_count) do return -2

	adjacency: [MAX_NODES]u64 = {}
	for edge: usize = 0; edge < edge_count; edge += 1 {
		left_label := values[edge_count_position + 1 + 2 * edge]
		right_label := values[edge_count_position + 2 + 2 * edge]
		left, right := node_count, node_count
		for index: usize = 0; index < node_count; index += 1 {
			if labels[index] == left_label do left = index
			if labels[index] == right_label do right = index
		}
		if left == node_count || right == node_count do return -2
		adjacency[left] |= u64(1) << u64(right)
		adjacency[right] |= u64(1) << u64(left)
	}

	stack: [MAX_NODES]usize = {}
	stack_length := usize(1)
	stack[0] = start_index
	route: [MAX_OUTPUT_BYTES]u8 = {}
	route_length := usize(0)
	for stack_length != 0 {
		stack_length -= 1
		current := stack[stack_length]
		if route_length == MAX_OUTPUT_BYTES do return -2
		route[route_length] = u8(labels[current])
		route_length += 1
		for neighbor: usize = 0; neighbor < node_count; neighbor += 1 {
			bit := u64(1) << u64(neighbor)
			if (adjacency[current] & bit) != 0 {
				pending := usize(0)
				for pending < stack_length && stack[pending] != neighbor { pending += 1 }
				if pending == stack_length {
					stack[stack_length] = neighbor
					stack_length += 1
				}
			}
			adjacency[current] &= ~bit
			adjacency[neighbor] &= ~(u64(1) << u64(current))
		}
		if labels[current] == target_label {
			if output_capacity < c.size_t(route_length) || (route_length != 0 && output == nil) do return -2
			for index: usize = 0; index < route_length; index += 1 { output[index] = route[index] }
			return i64(route_length)
		}
	}
	return 0
}
