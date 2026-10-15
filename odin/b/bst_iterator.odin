package bst_iterator

import "core:c"

MAX_NODE_COUNT :: 1023

@(export)
bst_iterator :: proc "contextless" (nodes: [^]i64, node_count: c.size_t,
		root_index: i64) -> i64 {
	if node_count > MAX_NODE_COUNT do return -1
	if node_count == 0 {
		if root_index == -1 do return 0
		return -1
	}
	if nodes == nil || root_index < 0 || u64(root_index) >= u64(node_count) do return -1
	iterator_values: [MAX_NODE_COUNT]i64
	stack: [MAX_NODE_COUNT]c.size_t
	top: c.size_t = 0
	value_count: c.size_t = 0
	current := root_index
	for current != -1 || top != 0 {
		for current != -1 {
			if current < 0 || u64(current) >= u64(node_count) || top >= node_count do return -1
			index := c.size_t(current)
			left, right := nodes[3 * index + 1], nodes[3 * index + 2]
			if left < -1 || (left >= 0 && u64(left) >= u64(node_count)) ||
				right < -1 || (right >= 0 && u64(right) >= u64(node_count)) {
				return -1
			}
			stack[top] = index
			top += 1
			current = left
		}
		top -= 1
		index := stack[top]
		if value_count >= node_count do return -1
		value := nodes[3 * index]
		if value < -100000 || value > 100000 ||
			(value_count != 0 && iterator_values[value_count - 1] >= value) {
			return -1
		}
		iterator_values[value_count] = value
		value_count += 1
		current = nodes[3 * index + 2]
	}
	if value_count != node_count do return -1
	checksum: i64 = 0
	for next_index: c.size_t = 0; next_index < value_count; next_index += 1 {
		checksum += (i64(next_index) + 1) * (iterator_values[next_index] + 100001)
	}
	return checksum
}
