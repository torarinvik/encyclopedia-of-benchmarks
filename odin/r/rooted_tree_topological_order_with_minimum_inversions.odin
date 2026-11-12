package rooted_tree_topological_order_with_minimum_inversions

import "core:c"

MAX_N :: 12
MAX_INPUT_VALUES :: 3 * MAX_N + 1
MAX_OUTPUT_WORDS :: MAX_N + 1
MAX_WEIGHT :: i64(1_000_000)

find_root :: proc "contextless" (parent: ^[MAX_N]int, vertex: int) -> int {
	root := vertex
	for parent[root] != root { root = parent[root] }
	current := vertex
	for parent[current] != current {
		next := parent[current]
		parent[current] = root
		current = next
	}
	return root
}

compare_ratio :: proc "contextless" (left_c, left_d, right_c, right_d: i64) -> int {
	left_zero := left_c == 0 && left_d == 0
	right_zero := right_c == 0 && right_d == 0
	if left_zero != right_zero {
		if left_zero do return -1
		return 1
	}
	lhs, rhs := left_c * right_d, left_d * right_c
	if lhs > rhs do return 1
	if lhs < rhs do return -1
	return 0
}

store_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8(bits >> (8 * byte))
	}
}

@(export)
rooted_tree_topological_order_with_minimum_inversions :: proc "c" (
	input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t,
) -> i64 {
	if input == nil || length < 3 || length > c.size_t(MAX_INPUT_VALUES) do return -1
	nv := input[0]
	if nv < 1 || nv > MAX_N || length != c.size_t(3 * nv) do return -1
	n := int(nv)

	var tree_parent: [MAX_N]int
	for vertex := 1; vertex < n; vertex += 1 {
		p := input[vertex]
		if p < 0 || p >= i64(vertex) do return -1
		tree_parent[vertex] = int(p)
	}

	var original_c, original_d, aggregate_c, aggregate_d: [MAX_N]i64
	sum_c, sum_d: i64 = 0, 0
	for vertex := 0; vertex < n; vertex += 1 {
		c_value, d_value := input[n + vertex], input[2 * n + vertex]
		if c_value < 0 || c_value > MAX_WEIGHT || d_value < 0 || d_value > MAX_WEIGHT do return -1
		sum_c += c_value
		sum_d += d_value
		if sum_c > MAX_WEIGHT || sum_d > MAX_WEIGHT do return -1
		original_c[vertex], original_d[vertex] = c_value, d_value
		aggregate_c[vertex], aggregate_d[vertex] = c_value, d_value
	}

	var dsu_parent, component_label, link: [MAX_N]int
	var active: [MAX_N]bool
	for vertex := 0; vertex < n; vertex += 1 {
		dsu_parent[vertex] = vertex
		component_label[vertex] = vertex
		active[vertex] = vertex != 0
		link[vertex] = vertex
	}

	for _ := 0; _ < n - 1; _ += 1 {
		selected := -1
		for candidate := 1; candidate < n; candidate += 1 {
			if !active[candidate] do continue
			if selected < 0 { selected = candidate; continue }
			comparison := compare_ratio(aggregate_c[candidate], aggregate_d[candidate],
				aggregate_c[selected], aggregate_d[selected])
			if comparison > 0 || (comparison == 0 && candidate > selected) do selected = candidate
		}
		if selected < 0 do return -1
		parent_component := find_root(&dsu_parent, tree_parent[selected])
		target := component_label[parent_component]
		child_component := find_root(&dsu_parent, selected)
		if child_component == parent_component do return -1
		aggregate_c[target] += aggregate_c[selected]
		aggregate_d[target] += aggregate_d[selected]
		dsu_parent[child_component] = parent_component
		component_label[parent_component] = target
		active[selected] = false
		if target != 0 do active[target] = true
		link[selected], link[target] = link[target], link[selected]
	}

	var traversal: [MAX_N]int
	count := 0
	vertex := link[0]
	for count < n {
		traversal[count] = vertex
		count += 1
		if vertex == 0 do break
		vertex = link[vertex]
	}
	if count != n || traversal[count - 1] != 0 do return -1

	var words: [MAX_OUTPUT_WORDS]i64
	prefix_d, objective: i64 = 0, 0
	for index := 0; index < n; index += 1 {
		ordered_vertex := traversal[n - 1 - index]
		words[index + 1] = i64(ordered_vertex)
		objective += prefix_d * original_c[ordered_vertex]
		prefix_d += original_d[ordered_vertex]
	}
	words[0] = objective
	output_bytes := c.size_t(8 * (n + 1))
	if output == nil || capacity < output_bytes do return -2
	for word := 0; word < n + 1; word += 1 {
		store_i64_le(output, 8 * word, words[word])
	}
	return i64(output_bytes)
}
