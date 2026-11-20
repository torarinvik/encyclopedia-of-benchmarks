package tree_center_rerooting_dp

import "core:c"

MAX_N :: 64
MAX_INPUT_LENGTH :: 1 + 2 * (MAX_N - 1)

store_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8(bits >> u64(8 * byte))
	}
}

@(export)
tree_center_rerooting_dp :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > MAX_INPUT_LENGTH do return -1
	n_value := input[0]
	if n_value < 1 || n_value > MAX_N do return -1
	n := int(n_value)
	if length != c.size_t(1 + 2 * (n - 1)) do return -1

	adjacency: [MAX_N * MAX_N]int = {}
	degree: [MAX_N]int
	for vertex := 0; vertex < n; vertex += 1 { degree[vertex] = 0 }
	for edge := 0; edge < n - 1; edge += 1 {
		offset := 1 + 2 * edge
		left_value := input[offset]
		right_value := input[offset + 1]
		if left_value < 0 || left_value >= n_value || right_value < 0 ||
			right_value >= n_value || left_value == right_value do return -1
		left := int(left_value)
		right := int(right_value)
		adjacency[left * MAX_N + degree[left]] = right
		degree[left] += 1
		adjacency[right * MAX_N + degree[right]] = left
		degree[right] += 1
	}

	parent: [MAX_N]int
	order: [MAX_N]int
	for vertex := 0; vertex < n; vertex += 1 { parent[vertex] = MAX_N }
	parent[0] = MAX_N + 1
	order[0] = 0
	order_count := 1
	position := 0
	for position < order_count {
		vertex := order[position]
		for edge := 0; edge < degree[vertex]; edge += 1 {
			child := adjacency[vertex * MAX_N + edge]
			if child == parent[vertex] do continue
			if parent[child] != MAX_N do return -1
			parent[child] = vertex
			order[order_count] = child
			order_count += 1
		}
		position += 1
	}
	if order_count != n do return -1

	down: [MAX_N]int = {}
	best: [MAX_N]int = {}
	second: [MAX_N]int = {}
	best_child: [MAX_N]int
	for vertex := 0; vertex < n; vertex += 1 { best_child[vertex] = MAX_N }
	position = n
	for position > 0 {
		position -= 1
		vertex := order[position]
		for edge := 0; edge < degree[vertex]; edge += 1 {
			child := adjacency[vertex * MAX_N + edge]
			if parent[child] != vertex do continue
			branch := down[child] + 1
			if branch > best[vertex] {
				second[vertex] = best[vertex]
				best[vertex] = branch
				best_child[vertex] = child
			} else if branch > second[vertex] {
				second[vertex] = branch
			}
		}
		down[vertex] = best[vertex]
	}

	outside: [MAX_N]int
	for vertex := 0; vertex < n; vertex += 1 { outside[vertex] = -1 }
	for i := 0; i < n; i += 1 {
		vertex := order[i]
		for edge := 0; edge < degree[vertex]; edge += 1 {
			child := adjacency[vertex * MAX_N + edge]
			if parent[child] != vertex do continue
			sibling := best[vertex]
			if best_child[vertex] == child { sibling = second[vertex] }
			base := outside[vertex]
			if sibling > base { base = sibling }
			outside[child] = base + 1
		}
	}

	radius := MAX_N
	for vertex := 0; vertex < n; vertex += 1 {
		eccentricity := down[vertex]
		if outside[vertex] > eccentricity { eccentricity = outside[vertex] }
		if eccentricity < radius { radius = eccentricity }
	}
	centers: [2]i64
	center_count := 0
	for vertex := 0; vertex < n; vertex += 1 {
		eccentricity := down[vertex]
		if outside[vertex] > eccentricity { eccentricity = outside[vertex] }
		if eccentricity == radius {
			centers[center_count] = i64(vertex)
			center_count += 1
		}
	}
	required := 8 * center_count
	if output == nil || capacity < c.size_t(required) do return -2
	for i := 0; i < center_count; i += 1 { store_i64_le(output, 8 * i, centers[i]) }
	return i64(required)
}
