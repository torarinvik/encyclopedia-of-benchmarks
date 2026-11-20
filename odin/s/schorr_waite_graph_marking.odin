package schorr_waite_graph_marking

import "core:c"

@(export)
schorr_waite_graph_marking :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 4 || length > 66 do return -1

	node_count_value := input[0]
	root := input[1]
	if node_count_value < 1 || node_count_value > 32 do return -1
	node_count := int(node_count_value)
	if length != c.size_t(2 + 2 * node_count) || root < 0 || root >= node_count_value do return -1

	left: [32]i64
	right: [32]i64
	marked: [32]bool
	phase: [32]bool
	for node := 0; node < node_count; node += 1 {
		left_child := input[2 + 2 * node]
		right_child := input[3 + 2 * node]
		if left_child < -1 || left_child >= node_count_value || right_child < -1 || right_child >= node_count_value do return -1
		left[node] = left_child
		right[node] = right_child
	}

	parent: i64 = -1
	current := root
	temporary: i64
	for parent != -1 || (current != -1 && !marked[int(current)]) {
		if current == -1 || marked[int(current)] {
			frame := int(parent)
			if phase[frame] {
				temporary = current
				current = parent
				parent = right[frame]
				right[frame] = temporary
			} else {
				temporary = current
				current = right[frame]
				right[frame] = left[frame]
				left[frame] = temporary
				phase[frame] = true
			}
		} else {
			temporary = parent
			parent = current
			current = left[int(parent)]
			left[int(parent)] = temporary
			marked[int(parent)] = true
			phase[int(parent)] = false
		}
	}

	reachable: i64 = 0
	for node := 0; node < node_count; node += 1 {
		if marked[node] do reachable |= i64(1) << node
	}
	return reachable
}
