package offline_range_paint_successor_dsu

import "core:c"

MAX_N :: 64
MAX_Q :: 64
MAX_INPUT_VALUES :: 195

find_successor :: proc "contextless" (parent: [^]i64, start: int) -> int {
	node, root := start, start
	for parent[root] != i64(root) { root = int(parent[root]) }
	for parent[node] != i64(node) {
		next := int(parent[node])
		parent[node] = i64(root)
		node = next
	}
	return root
}

@(export)
offline_range_paint_successor_dsu :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT_VALUES do return -1
	n_value, q_value := input[0], input[1]
	if n_value < 1 || n_value > MAX_N || q_value < 0 || q_value > MAX_Q do return -1
	n, q := int(n_value), int(q_value)
	if length != c.size_t(2 + 3*q) do return -1
	left: [MAX_Q]i64
	right: [MAX_Q]i64
	color: [MAX_Q]i64
	for j := 0; j < q; j += 1 {
		left[j], right[j], color[j] = input[2+3*j], input[3+3*j], input[4+3*j]
		if left[j] < 0 || left[j] > right[j] || right[j] >= n_value ||
			color[j] < -1000 || color[j] > 1000 do return -1
	}
	parent: [MAX_N+1]i64
	final_color: [MAX_N]i64
	for i := 0; i <= n; i += 1 { parent[i] = i64(i) }
	for j := q; j > 0; j -= 1 {
		operation := j - 1
		cell := find_successor(&parent[0], int(left[operation]))
		for cell <= int(right[operation]) {
			final_color[cell] = color[operation]
			parent[cell] = i64(find_successor(&parent[0], cell+1))
			cell = find_successor(&parent[0], cell)
		}
	}
	checksum := i64(0)
	for i := 0; i < n; i += 1 { checksum += i64(i+1) * (final_color[i] + 1001) }
	return checksum
}
