package tree_center

import "core:c"

MAX_N :: 64
MAX_INPUT_LENGTH :: 1 + 2 * (MAX_N - 1)
MATRIX_CELLS :: MAX_N * MAX_N

find_root :: proc "contextless" (parent: [^]int, item: int) -> int {
	node := item
	for parent[node] != node {
		parent[node] = parent[parent[node]]
		node = parent[node]
	}
	return node
}

store_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8(bits >> u64(8 * byte))
	}
}

@(export)
tree_center :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > MAX_INPUT_LENGTH do return -1
	n_value := input[0]
	if n_value < 1 || n_value > MAX_N do return -1
	n := int(n_value)
	if length != c.size_t(1 + 2 * (n - 1)) do return -1

	adjacency: [MATRIX_CELLS]int
	adjacency_count: [MAX_N]int
	degree: [MAX_N]int
	parent: [MAX_N]int
	component_size: [MAX_N]int
	for vertex := 0; vertex < n; vertex += 1 {
		parent[vertex] = vertex
		component_size[vertex] = 1
		adjacency_count[vertex] = 0
		degree[vertex] = 0
	}
	for edge := 0; edge < n - 1; edge += 1 {
		offset := 1 + 2 * edge
		left_value := input[offset]
		right_value := input[offset + 1]
		if left_value < 0 || left_value >= n_value || right_value < 0 ||
			right_value >= n_value || left_value == right_value do return -1
		left := int(left_value)
		right := int(right_value)
		root_left := find_root(&parent[0], left)
		root_right := find_root(&parent[0], right)
		if root_left == root_right do return -1
		if component_size[root_left] < component_size[root_right] {
			temporary := root_left
			root_left = root_right
			root_right = temporary
		}
		parent[root_right] = root_left
		component_size[root_left] += component_size[root_right]
		adjacency[left * MAX_N + adjacency_count[left]] = right
		adjacency_count[left] += 1
		adjacency[right * MAX_N + adjacency_count[right]] = left
		adjacency_count[right] += 1
		degree[left] += 1
		degree[right] += 1
	}
	if n > 1 && component_size[find_root(&parent[0], 0)] != n do return -1

	active: [MAX_N]bool
	leaves: [MAX_N]int
	leaf_count := 0
	for vertex := 0; vertex < n; vertex += 1 {
		active[vertex] = true
		if degree[vertex] <= 1 {
			leaves[leaf_count] = vertex
			leaf_count += 1
		}
	}
	remaining := n
	for remaining > 2 {
		for index := 0; index < leaf_count; index += 1 do active[leaves[index]] = false
		remaining -= leaf_count
		for index := 0; index < leaf_count; index += 1 {
			leaf := leaves[index]
			for edge := 0; edge < adjacency_count[leaf]; edge += 1 {
				neighbor := adjacency[leaf * MAX_N + edge]
				if active[neighbor] do degree[neighbor] -= 1
			}
		}
		if remaining <= 2 do break
		leaf_count = 0
		for vertex := 0; vertex < n; vertex += 1 {
			if active[vertex] && degree[vertex] == 1 {
				leaves[leaf_count] = vertex
				leaf_count += 1
			}
		}
	}

	centers: [2]i64
	center_count := 0
	for vertex := 0; vertex < n; vertex += 1 {
		if active[vertex] {
			centers[center_count] = i64(vertex)
			center_count += 1
		}
	}
	required := 8 * center_count
	if output == nil || capacity < c.size_t(required) do return -2
	for index := 0; index < center_count; index += 1 {
		store_i64_le(output, 8 * index, centers[index])
	}
	return i64(required)
}
