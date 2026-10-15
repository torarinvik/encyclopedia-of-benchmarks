package trim_bst

import "core:c"

MAX_NODE_COUNT :: 100
MAX_VALUE :: i64(10000)

valid_bst :: proc "contextless" (nodes: [^]i64, node_count, root_index: int) -> bool {
	parents: [MAX_NODE_COUNT]int
	for index := 0; index < node_count; index += 1 {
		value := nodes[3 * index]
		left, right := nodes[3 * index + 1], nodes[3 * index + 2]
		if value < 1 || value > MAX_VALUE || left < -1 || right < -1 ||
			(left >= 0 && left >= i64(node_count)) || (right >= 0 && right >= i64(node_count)) {
			return false
		}
		if left >= 0 {
			parents[int(left)] += 1
			if parents[int(left)] > 1 do return false
		}
		if right >= 0 {
			parents[int(right)] += 1
			if parents[int(right)] > 1 do return false
		}
	}
	if parents[root_index] != 0 do return false
	for index := 0; index < node_count; index += 1 {
		if index != root_index && parents[index] != 1 do return false
	}

	stack_node: [MAX_NODE_COUNT]int
	stack_low: [MAX_NODE_COUNT]i64
	stack_high: [MAX_NODE_COUNT]i64
	seen: [MAX_NODE_COUNT]bool
	stack_node[0] = root_index
	stack_low[0] = 0
	stack_high[0] = MAX_VALUE + 1
	top := 1
	visited := 0
	for top > 0 {
		top -= 1
		index := stack_node[top]
		lower, upper := stack_low[top], stack_high[top]
		if seen[index] do return false
		seen[index] = true
		visited += 1
		value := nodes[3 * index]
		if value <= lower || value >= upper do return false
		left, right := nodes[3 * index + 1], nodes[3 * index + 2]
		if right >= 0 {
			stack_node[top] = int(right)
			stack_low[top] = value
			stack_high[top] = upper
			top += 1
		}
		if left >= 0 {
			stack_node[top] = int(left)
			stack_low[top] = lower
			stack_high[top] = value
			top += 1
		}
	}
	return visited == node_count
}

trim_node :: proc "contextless" (nodes: [^]i64, node: i64, low, high: i64,
		output: [^]i64, output_count: ^int) -> i64 {
	if node == -1 do return -1
	index := int(node)
	value := nodes[3 * index]
	left, right := nodes[3 * index + 1], nodes[3 * index + 2]
	if value < low do return trim_node(nodes, right, low, high, output, output_count)
	if value > high do return trim_node(nodes, left, low, high, output, output_count)
	trimmed_index := output_count^
	output_count^ += 1
	offset := 1 + 3 * trimmed_index
	output[offset] = value
	output[offset + 1] = -1
	output[offset + 2] = -1
	output[offset + 1] = trim_node(nodes, left, low, high, output, output_count)
	output[offset + 2] = trim_node(nodes, right, low, high, output, output_count)
	return i64(trimmed_index)
}

@(export)
trim_bst :: proc "c" (nodes: [^]i64, node_count: c.size_t, root_index: i64,
		low, high: i64, output: [^]i64, output_capacity: c.size_t) -> i64 {
	if node_count > MAX_NODE_COUNT || low < 1 || high > MAX_VALUE || low > high do return -1
	if node_count == 0 {
		if root_index != -1 do return -1
		if output == nil || output_capacity < 1 do return -2
		output[0] = -1
		return 1
	}
	if nodes == nil || root_index < 0 || u64(root_index) >= u64(node_count) do return -1
	count := int(node_count)
	root := int(root_index)
	if !valid_bst(nodes, count, root) do return -1
	if output == nil || output_capacity < c.size_t(1 + 3 * count) do return -2
	output_count := 0
	output[0] = trim_node(nodes, root_index, low, high, output, &output_count)
	return i64(1 + 3 * output_count)
}
