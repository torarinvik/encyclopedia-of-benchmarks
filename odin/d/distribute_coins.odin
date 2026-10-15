package distribute_coins

import "core:c"

MAX_NODE_COUNT :: 100

absolute_i64 :: proc "contextless" (value: i64) -> i64 {
	if value < 0 do return -value
	return value
}

analyze :: proc "contextless" (nodes: [^]i64, node: i64, moves: ^i64) -> i64 {
	if node == -1 do return 1
	index := int(node)
	left := nodes[3 * index + 1]
	right := nodes[3 * index + 2]
	left_excess := analyze(nodes, left, moves)
	right_excess := analyze(nodes, right, moves)
	moves^ += absolute_i64(1 - left_excess) + absolute_i64(1 - right_excess)
	return nodes[3 * index] + left_excess + right_excess - 2
}

@(export)
distribute_coins :: proc "contextless" (nodes: [^]i64, node_count: c.size_t,
		root_index: i64) -> i64 {
	if node_count > c.size_t(MAX_NODE_COUNT) do return -1
	if node_count == 0 {
		if root_index == -1 do return 0
		return -1
	}
	count := int(node_count)
	if root_index < 0 || root_index >= i64(count) do return -1
	root := int(root_index)

	parent: [MAX_NODE_COUNT]i64 = {}
	stack: [MAX_NODE_COUNT]int = {}
	seen: [MAX_NODE_COUNT]bool = {}
	for node := 0; node < count; node += 1 do parent[node] = -1
	coin_total: i64 = 0
	for node := 0; node < count; node += 1 {
		value := nodes[3 * node]
		if value < 0 || value > 100 do return -1
		coin_total += value
		for edge := 1; edge <= 2; edge += 1 {
			child := nodes[3 * node + edge]
			if child < -1 || child >= i64(count) do return -1
			if child >= 0 {
				child_index := int(child)
				if parent[child_index] != -1 do return -1
				parent[child_index] = i64(node)
			}
		}
	}
	if coin_total != i64(count) do return -1
	if parent[root] != -1 do return -1
	for node := 0; node < count; node += 1 {
		if node != root && parent[node] == -1 do return -1
	}

	top := 0
	reached := 0
	stack[top] = root
	top += 1
	for top > 0 {
		top -= 1
		node := stack[top]
		if seen[node] do return -1
		seen[node] = true
		reached += 1
		for edge := 1; edge <= 2; edge += 1 {
			child := nodes[3 * node + edge]
			if child >= 0 {
				stack[top] = int(child)
				top += 1
			}
		}
	}
	if reached != count do return -1

	moves: i64 = 0
	_ = analyze(nodes, root_index, &moves)
	return moves
}
