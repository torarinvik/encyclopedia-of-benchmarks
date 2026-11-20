package same_fringe_leaf_iterator

import "core:c"

MAX_TREE_NODES :: 15
MAX_TOTAL_NODES :: 30
MAX_PARSEABLE_LENGTH :: 93

valid_tree :: proc(input: [^]i64, offset, node_count: int) -> bool {
	visited: [15]bool = {}
	parents: [15]int = {}
	stack: [15]int = {}
	top := 1
	reached := 0
	for top > 0 {
		top -= 1
		node := stack[top]
		if node < 0 || node >= node_count || visited[node] do return false
		visited[node] = true
		reached += 1
		base := offset + 3 * node
		left := input[base + 1]
		right := input[base + 2]
		if left == -1 && right == -1 do continue
		if left < 0 || right < 0 || left >= i64(node_count) || right >= i64(node_count) ||
			left == right || left == 0 || right == 0 do return false
		parents[int(left)] += 1
		parents[int(right)] += 1
		if parents[int(left)] != 1 || parents[int(right)] != 1 do return false
		stack[top] = int(right)
		top += 1
		stack[top] = int(left)
		top += 1
	}
	if reached != node_count || parents[0] != 0 do return false
	for node := 1; node < node_count; node += 1 {
		if parents[node] != 1 do return false
	}
	return true
}

@(export)
same_fringe_leaf_iterator :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > c.size_t(MAX_PARSEABLE_LENGTH) do return -1
	n_a_word := input[0]
	n_b_word := input[1]
	if n_a_word < 1 || n_a_word > i64(MAX_TREE_NODES) ||
		n_b_word < 1 || n_b_word > i64(MAX_TREE_NODES) do return -1
	n_a := int(n_a_word)
	n_b := int(n_b_word)
	if n_a + n_b > MAX_TOTAL_NODES || int(length) != 2 + 3 * (n_a + n_b) do return -1
	offset_a := 2
	offset_b := 2 + 3 * n_a
	if !valid_tree(input, offset_a, n_a) || !valid_tree(input, offset_b, n_b) do return -1

	stack_a: [15]int = {}
	stack_b: [15]int = {}
	top_a := 1
	top_b := 1
	for {
		have_a := false
		have_b := false
		leaf_a: i64 = 0
		leaf_b: i64 = 0
		for top_a > 0 && !have_a {
			top_a -= 1
			node := stack_a[top_a]
			base := offset_a + 3 * node
			left := input[base + 1]
			right := input[base + 2]
			if left == -1 {
				leaf_a = input[base]
				have_a = true
			} else {
				stack_a[top_a] = int(right)
				top_a += 1
				stack_a[top_a] = int(left)
				top_a += 1
			}
		}
		for top_b > 0 && !have_b {
			top_b -= 1
			node := stack_b[top_b]
			base := offset_b + 3 * node
			left := input[base + 1]
			right := input[base + 2]
			if left == -1 {
				leaf_b = input[base]
				have_b = true
			} else {
				stack_b[top_b] = int(right)
				top_b += 1
				stack_b[top_b] = int(left)
				top_b += 1
			}
		}
		if !have_a || !have_b {
			if have_a == have_b do return 1
			return 0
		}
		if leaf_a != leaf_b do return 0
	}
	return -1
}
