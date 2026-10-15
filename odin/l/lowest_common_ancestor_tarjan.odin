package lowest_common_ancestor_tarjan

import "core:c"

MAX_NODE_COUNT :: 256
MAX_QUERY_COUNT :: 1024
MAX_ADJACENCY_COUNT :: 2 * (MAX_NODE_COUNT - 1)
MAX_QUERY_ADJACENCY_COUNT :: 2 * MAX_QUERY_COUNT

find_root :: proc "contextless" (parent: [^]int, node: int) -> int {
	root := node
	for parent[root] != root do root = parent[root]
	current := node
	for parent[current] != current {
		next := parent[current]
		parent[current] = root
		current = next
	}
	return root
}

unite :: proc "contextless" (parent: [^]int, rank: [^]int, left, right: int) {
	left_root := find_root(parent, left)
	right_root := find_root(parent, right)
	if left_root == right_root do return
	if rank[left_root] < rank[right_root] do parent[left_root] = right_root
	else if rank[left_root] > rank[right_root] do parent[right_root] = left_root
	else {
		parent[right_root] = left_root
		rank[left_root] += 1
	}
}

@(export)
lowest_common_ancestor_tarjan :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 4 || input[0] < 1 || input[0] > MAX_NODE_COUNT do return -1
	node_count := int(input[0])
	if input[1] < 0 || input[1] >= i64(node_count) || input[2] != i64(node_count - 1) ||
		input[3] < 0 || input[3] > MAX_QUERY_COUNT do return -1
	root := int(input[1])
	edge_count := int(input[2])
	query_count := int(input[3])
	if int(length) != 4 + 2 * edge_count + 2 * query_count do return -1

	validation_parent := [MAX_NODE_COUNT]int{}
	dsu_parent := [MAX_NODE_COUNT]int{}
	ancestor := [MAX_NODE_COUNT]int{}
	validation_rank := [MAX_NODE_COUNT]int{}
	dsu_rank := [MAX_NODE_COUNT]int{}
	edge_head := [MAX_NODE_COUNT]i64{}
	edge_to := [MAX_ADJACENCY_COUNT]i64{}
	edge_next := [MAX_ADJACENCY_COUNT]i64{}
	query_head := [MAX_NODE_COUNT]i64{}
	query_to := [MAX_QUERY_ADJACENCY_COUNT]i64{}
	query_next := [MAX_QUERY_ADJACENCY_COUNT]i64{}
	query_id := [MAX_QUERY_ADJACENCY_COUNT]i64{}
	answers := [MAX_QUERY_COUNT]i64{}
	tree_parent := [MAX_NODE_COUNT]i64{}
	cursor := [MAX_NODE_COUNT]i64{}
	visited := [MAX_NODE_COUNT]bool{}
	finished := [MAX_NODE_COUNT]bool{}
	stack := [MAX_NODE_COUNT]int{}
	for node := 0; node < node_count; node += 1 {
		validation_parent[node] = node
		dsu_parent[node] = node
		ancestor[node] = node
		edge_head[node] = -1
		query_head[node] = -1
		tree_parent[node] = -1
	}
	for edge := 0; edge < edge_count; edge += 1 {
		left_arg := input[4 + 2 * edge]
		right_arg := input[5 + 2 * edge]
		if left_arg < 0 || right_arg < 0 || left_arg >= i64(node_count) ||
			right_arg >= i64(node_count) || left_arg == right_arg do return -1
		left := int(left_arg)
		right := int(right_arg)
		if find_root(&validation_parent[0], left) == find_root(&validation_parent[0], right) do return -1
		unite(&validation_parent[0], &validation_rank[0], left, right)
		forward := 2 * edge
		reverse := forward + 1
		edge_to[forward] = i64(right)
		edge_next[forward] = edge_head[left]
		edge_head[left] = i64(forward)
		edge_to[reverse] = i64(left)
		edge_next[reverse] = edge_head[right]
		edge_head[right] = i64(reverse)
	}
	root_component := find_root(&validation_parent[0], root)
	for node := 0; node < node_count; node += 1 {
		if find_root(&validation_parent[0], node) != root_component do return -1
	}
	for query := 0; query < query_count; query += 1 {
		left_arg := input[4 + 2 * edge_count + 2 * query]
		right_arg := input[5 + 2 * edge_count + 2 * query]
		if left_arg < 0 || right_arg < 0 || left_arg >= i64(node_count) || right_arg >= i64(node_count) do return -1
		left := int(left_arg)
		right := int(right_arg)
		first := 2 * query
		second := first + 1
		query_to[first] = i64(right)
		query_id[first] = i64(query)
		query_next[first] = query_head[left]
		query_head[left] = i64(first)
		query_to[second] = i64(left)
		query_id[second] = i64(query)
		query_next[second] = query_head[right]
		query_head[right] = i64(second)
	}
	if query_count > int(output_capacity) || (query_count != 0 && output == nil) do return -2

	top := 1
	stack[0] = root
	visited[root] = true
	cursor[root] = edge_head[root]
	for top > 0 {
		node := stack[top - 1]
		edge := cursor[node]
		if edge >= 0 {
			cursor[node] = edge_next[int(edge)]
			child := int(edge_to[int(edge)])
			if child == int(tree_parent[node]) do continue
			if visited[child] do return -1
			visited[child] = true
			tree_parent[child] = i64(node)
			cursor[child] = edge_head[child]
			stack[top] = child
			top += 1
			continue
		}
		finished[node] = true
		item := query_head[node]
		for item >= 0 {
			index := int(item)
			other := int(query_to[index])
			if finished[other] do answers[int(query_id[index])] = i64(ancestor[find_root(&dsu_parent[0], other)])
			item = query_next[index]
		}
		top -= 1
		if tree_parent[node] >= 0 {
			parent := int(tree_parent[node])
			unite(&dsu_parent[0], &dsu_rank[0], parent, node)
			component := find_root(&dsu_parent[0], parent)
			ancestor[component] = parent
		}
	}
	for query := 0; query < query_count; query += 1 do output[query] = u8(answers[query])
	return i64(query_count)
}
