package jump_on_tree

import "core:c"

MAX_N :: 64
MAX_Q :: 64
MAX_LEVELS :: 7
MAX_INPUT_VALUES :: 2 + 2 * (MAX_N - 1) + 3 * MAX_Q

find_root :: proc "contextless" (parent: [^]int, item: int) -> int {
	current := item
	for parent[current] != current {
		parent[current] = parent[parent[current]]
		current = parent[current]
	}
	return current
}

lift :: proc "contextless" (ancestors: [^][MAX_LEVELS]int, vertex, distance: int) -> int {
	current := vertex
	for bit := 0; bit < MAX_LEVELS; bit += 1 {
		if ((distance >> bit) & 1) != 0 do current = ancestors[current][bit]
	}
	return current
}

lowest_common_ancestor :: proc "contextless" (ancestors: [^][MAX_LEVELS]int,
	depth: [^]int, left_value, right_value: int) -> int {
	left := left_value
	right := right_value
	if depth[left] < depth[right] {
		temporary := left
		left = right
		right = temporary
	}
	left = lift(ancestors, left, depth[left] - depth[right])
	if left == right do return left
	for level := MAX_LEVELS; level > 0; level -= 1 {
		bit := level - 1
		if ancestors[left][bit] != ancestors[right][bit] {
			left = ancestors[left][bit]
			right = ancestors[right][bit]
		}
	}
	return ancestors[left][0]
}

store_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8(bits >> (8 * byte))
	}
}

@(export)
jump_on_tree :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT_VALUES do return -1
	n_value := input[0]
	q_value := input[1]
	if n_value < 2 || n_value > int64(MAX_N) || q_value < 1 || q_value > int64(MAX_Q) do return -1
	n := int(n_value)
	q := int(q_value)
	query_start := 2 + 2 * (n - 1)
	if length != c.size_t(query_start + 3 * q) do return -1

	adjacent: [MAX_N][MAX_N]bool
	dsu_parent: [MAX_N]int
	dsu_size: [MAX_N]int
	for vertex := 0; vertex < n; vertex += 1 {
		dsu_parent[vertex] = vertex
		dsu_size[vertex] = 1
	}
	for edge := 0; edge < n - 1; edge += 1 {
		offset := 2 + 2 * edge
		left_value := input[offset]
		right_value := input[offset + 1]
		if left_value < 0 || left_value >= n_value || right_value < 0 ||
			right_value >= n_value || left_value == right_value do return -1
		left := int(left_value)
		right := int(right_value)
		root_left := find_root(&dsu_parent[0], left)
		root_right := find_root(&dsu_parent[0], right)
		if root_left == root_right do return -1
		if dsu_size[root_left] < dsu_size[root_right] {
			temporary := root_left
			root_left = root_right
			root_right = temporary
		}
		dsu_parent[root_right] = root_left
		dsu_size[root_left] += dsu_size[root_right]
		adjacent[left][right] = true
		adjacent[right][left] = true
	}

	ancestors: [MAX_N][MAX_LEVELS]int
	depth: [MAX_N]int
	visited: [MAX_N]bool
	stack: [MAX_N]int
	top := 1
	stack[0] = 0
	visited[0] = true
	for top > 0 {
		top -= 1
		vertex := stack[top]
		for neighbor := 0; neighbor < n; neighbor += 1 {
			if !adjacent[vertex][neighbor] || visited[neighbor] do continue
			visited[neighbor] = true
			ancestors[neighbor][0] = vertex
			depth[neighbor] = depth[vertex] + 1
			stack[top] = neighbor
			top += 1
		}
	}
	for level := 1; level < MAX_LEVELS; level += 1 {
		for vertex := 0; vertex < n; vertex += 1 {
			ancestors[vertex][level] = ancestors[ancestors[vertex][level - 1]][level - 1]
		}
	}

	answers: [MAX_Q]i64
	for query := 0; query < q; query += 1 {
		offset := query_start + 3 * query
		start_value := input[offset]
		target_value := input[offset + 1]
		index_value := input[offset + 2]
		if start_value < 0 || start_value >= n_value || target_value < 0 ||
			target_value >= n_value || index_value < 0 || index_value >= n_value do return -1
		start := int(start_value)
		target := int(target_value)
		index := int(index_value)
		common := lowest_common_ancestor(&ancestors[0], &depth[0], start, target)
		upward := depth[start] - depth[common]
		path_length := upward + depth[target] - depth[common]
		if index > path_length do answers[query] = -1
		else if index <= upward do answers[query] = i64(lift(&ancestors[0], start, index))
		else do answers[query] = i64(lift(&ancestors[0], target, path_length - index))
	}

	required := 8 * q
	if output == nil || capacity < c.size_t(required) do return -2
	for query := 0; query < q; query += 1 do store_i64_le(output, 8 * query, answers[query])
	return i64(required)
}
