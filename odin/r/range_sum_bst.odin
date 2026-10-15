package range_sum_bst

import "core:c"

MAX_NODE_COUNT :: 1023
MAX_VALUE :: 100000

// Preserve the source's full tree traversal while validating the BST input.
@(export)
range_sum_bst :: proc "contextless" (nodes: [^]i64, node_count: c.size_t,
		root_index, low, high: i64) -> i64 {
	if node_count > MAX_NODE_COUNT || low < 1 || high > MAX_VALUE || low > high do return -1
	if node_count == 0 {
		if root_index == -1 do return 0
		return -1
	}
	if nodes == nil || root_index < 0 || u64(root_index) >= u64(node_count) { return -1 }

	parents: [MAX_NODE_COUNT]i64 = {}
	seen: [MAX_NODE_COUNT]bool = {}
	stack_node, stack_low, stack_high: [MAX_NODE_COUNT]i64
	for index := 0; index < MAX_NODE_COUNT; index += 1 {
		parents[index] = 0
		seen[index] = false
	}
	for index := 0; index < int(node_count); index += 1 {
		value := nodes[3 * index]
		left := nodes[3 * index + 1]
		right := nodes[3 * index + 2]
		if value < 1 || value > MAX_VALUE || left < -1 || right < -1 ||
			(left >= 0 && u64(left) >= u64(node_count)) ||
			(right >= 0 && u64(right) >= u64(node_count)) { return -1 }
		if left >= 0 {
			parents[int(left)] += 1
			if parents[int(left)] > 1 do return -1
		}
		if right >= 0 {
			parents[int(right)] += 1
			if parents[int(right)] > 1 do return -1
		}
	}
	root := int(root_index)
	if parents[root] != 0 do return -1
	for index := 0; index < int(node_count); index += 1 {
		if index != root && parents[index] != 1 do return -1
	}

	top := 1
	visited := 0
	stack_node[0] = root_index
	stack_low[0] = 0
	stack_high[0] = MAX_VALUE + 1
	total: i64 = 0
	for top > 0 {
		top -= 1
		index := int(stack_node[top])
		lower, upper := stack_low[top], stack_high[top]
		if seen[index] do return -1
		seen[index] = true
		visited += 1
		value := nodes[3 * index]
		left, right := nodes[3 * index + 1], nodes[3 * index + 2]
		if value <= lower || value >= upper do return -1
		if low <= value && value <= high { total += value }
		if right >= 0 {
			stack_node[top] = right
			stack_low[top] = value
			stack_high[top] = upper
			top += 1
		}
		if left >= 0 {
			stack_node[top] = left
			stack_low[top] = lower
			stack_high[top] = value
			top += 1
		}
	}
	if visited != int(node_count) do return -1
	return total
}
