package frequency_table_of_tree_distance

import "core:c"

MAX_N :: 64
MAX_INPUT_VALUES :: 1 + 2 * (MAX_N - 1)

find_root :: proc "contextless" (parent: [^]int, item: int) -> int {
	current := item
	for parent[current] != current {
		parent[current] = parent[parent[current]]
		current = parent[current]
	}
	return current
}

solve_component :: proc (n: int, adjacent: [^][MAX_N]bool, removed: [^]bool,
	answer: [^]i64, start: int) {
	order: [MAX_N]int
	parent: [MAX_N]int
	subtree: [MAX_N]int
	stack: [MAX_N]int
	order_count := 0
	top := 1
	stack[0] = start
	parent[start] = start
	subtree[start] = 1
	order[order_count] = start
	order_count += 1
	for top > 0 {
		top -= 1
		vertex := stack[top]
		for neighbor := 0; neighbor < n; neighbor += 1 {
			if !adjacent[vertex][neighbor] || removed[neighbor] || neighbor == parent[vertex] do continue
			parent[neighbor] = vertex
			subtree[neighbor] = 1
			order[order_count] = neighbor
			order_count += 1
			stack[top] = neighbor
			top += 1
		}
	}
	position := order_count
	for position > 1 {
		position -= 1
		vertex := order[position]
		subtree[parent[vertex]] += subtree[vertex]
	}

	centroid := MAX_N
	for position := 0; position < order_count; position += 1 {
		vertex := order[position]
		largest_part := order_count - subtree[vertex]
		for neighbor := 0; neighbor < n; neighbor += 1 {
			if adjacent[vertex][neighbor] && !removed[neighbor] && parent[neighbor] == vertex &&
				subtree[neighbor] > largest_part do largest_part = subtree[neighbor]
		}
		if 2 * largest_part <= order_count && (centroid == MAX_N || vertex < centroid) do centroid = vertex
	}

	frequency: [MAX_N]i64
	frequency_max := 0
	frequency[0] = 1
	removed[centroid] = true
	for child := 0; child < n; child += 1 {
		if !adjacent[centroid][child] || removed[child] do continue
		local_frequency: [MAX_N]int
		walk_vertex: [MAX_N]int
		walk_parent: [MAX_N]int
		walk_depth: [MAX_N]int
		local_max := 0
		walk_top := 1
		walk_vertex[0] = child
		walk_parent[0] = centroid
		walk_depth[0] = 1
		for walk_top > 0 {
			walk_top -= 1
			vertex := walk_vertex[walk_top]
			previous := walk_parent[walk_top]
			depth := walk_depth[walk_top]
			local_frequency[depth] += 1
			if depth > local_max do local_max = depth
			for neighbor := 0; neighbor < n; neighbor += 1 {
				if adjacent[vertex][neighbor] && !removed[neighbor] && neighbor != previous {
					walk_vertex[walk_top] = neighbor
					walk_parent[walk_top] = vertex
					walk_depth[walk_top] = depth + 1
					walk_top += 1
				}
			}
		}
		for depth := 1; depth <= local_max; depth += 1 {
			for other := 0; other <= frequency_max; other += 1 {
				if depth + other < n do answer[depth + other] += i64(local_frequency[depth]) * frequency[other]
			}
		}
		for depth := 1; depth <= local_max; depth += 1
			frequency[depth] += i64(local_frequency[depth])
		if local_max > frequency_max do frequency_max = local_max
	}

	for child := 0; child < n; child += 1 {
		if adjacent[centroid][child] && !removed[child]
			solve_component(n, adjacent, removed, answer, child)
	}
}

store_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 do output[offset + byte] = u8(bits >> (8 * byte))
}

@(export)
frequency_table_of_tree_distance :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > MAX_INPUT_VALUES do return -1
	n_value := input[0]
	if n_value < 1 || n_value > i64(MAX_N) do return -1
	n := int(n_value)
	if length != c.size_t(1 + 2 * (n - 1)) do return -1

	adjacent: [MAX_N][MAX_N]bool
	dsu_parent: [MAX_N]int
	dsu_size: [MAX_N]int
	for vertex := 0; vertex < n; vertex += 1 {
		dsu_parent[vertex] = vertex
		dsu_size[vertex] = 1
	}
	for edge := 0; edge < n - 1; edge += 1 {
		offset := 1 + 2 * edge
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

	removed: [MAX_N]bool
	answer: [MAX_N]i64
	solve_component(n, &adjacent[0], &removed[0], &answer[0], 0)
	required := 8 * (n - 1)
	if output == nil || capacity < c.size_t(required) do return -2
	for distance := 1; distance < n; distance += 1
		store_i64_le(output, 8 * (distance - 1), answer[distance])
	return i64(required)
}
