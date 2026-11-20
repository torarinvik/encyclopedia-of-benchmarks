package lazy_segment_tree_range_add_max_right

import "core:c"

MAX_VALID_LENGTH :: 66
MAX_PARSEABLE_LENGTH :: 67
TREE_LENGTH :: 64

apply :: proc "contextless" (tree, pending: [^]i64, node, segment_length: int, delta: i64) {
	tree[node] += delta * i64(segment_length)
	pending[node] += delta
}

push :: proc "contextless" (tree, pending: [^]i64, node, segment_length: int) {
	if segment_length > 1 && pending[node] != 0 {
		half := segment_length / 2
		delta := pending[node]
		apply(tree, pending, 2 * node, half, delta)
		apply(tree, pending, 2 * node + 1, half, delta)
		pending[node] = 0
	}
}

range_add :: proc "contextless" (tree, pending: [^]i64, node, low, high, query_low, query_high: int, delta: i64) {
	if query_low >= query_high do return
	if query_high <= low || high <= query_low do return
	if query_low <= low && high <= query_high {
		apply(tree, pending, node, high - low, delta)
		return
	}
	push(tree, pending, node, high - low)
	middle := (low + high) / 2
	if query_low < middle do range_add(tree, pending, 2 * node, low, middle, query_low, query_high, delta)
	if query_high > middle do range_add(tree, pending, 2 * node + 1, middle, high, query_low, query_high, delta)
	tree[node] = tree[2 * node] + tree[2 * node + 1]
}

max_right :: proc "contextless" (tree, pending: [^]i64, node, low, high, n, left: int, limit: i64, accumulated: ^i64) -> int {
	if high <= left do return high
	if low >= n do return n
	if left <= low && high <= n && accumulated^ + tree[node] <= limit {
		accumulated^ += tree[node]
		return high
	}
	if high - low == 1 do return low
	push(tree, pending, node, high - low)
	middle := (low + high) / 2
	first := max_right(tree, pending, 2 * node, low, middle, n, left, limit, accumulated)
	if first < middle && first >= left do return first
	return max_right(tree, pending, 2 * node + 1, middle, high, n, left, limit, accumulated)
}

@(export)
lazy_segment_tree_range_add_max_right :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 3 || length > MAX_PARSEABLE_LENGTH do return -1
	if input[0] < 1 || input[0] > 16 || input[1] < 0 || input[1] > 12 do return -1
	n := int(input[0])
	operations := int(input[1])
	if int(length) != 2 + n + 4 * operations || int(length) > MAX_VALID_LENGTH do return -1
	for i := 0; i < n; i += 1 {
		if input[2 + i] < 0 || input[2 + i] > 31 do return -1
	}
	for operation := 0; operation < operations; operation += 1 {
		p := 2 + n + 4 * operation
		opcode, left, right, extra := input[p], input[p + 1], input[p + 2], input[p + 3]
		if opcode == 0 {
			if left < 0 || left > i64(n) || right < left || right > i64(n) || extra < 0 || extra > 31 do return -1
		} else if opcode == 1 {
			if left < 0 || left > i64(n) || right < 0 || right > 8192 || extra != 0 do return -1
		} else do return -1
	}

	base := 1
	for base < n do base *= 2
	var tree: [TREE_LENGTH]i64
	var pending: [TREE_LENGTH]i64
	for i := 0; i < TREE_LENGTH; i += 1 { tree[i] = 0; pending[i] = 0 }
	for i := 0; i < n; i += 1 { tree[base + i] = input[2 + i] }
	for node := base - 1; node > 0; node -= 1 { tree[node] = tree[node * 2] + tree[node * 2 + 1] }

	query_index := 0
	result: i64 = 0
	for operation := 0; operation < operations; operation += 1 {
		p := 2 + n + 4 * operation
		left, right := int(input[p + 1]), int(input[p + 2])
		if input[p] == 0 {
			range_add(&tree[0], &pending[0], 1, 0, base, left, right, input[p + 3])
		} else {
			accumulated: i64 = 0
			boundary := max_right(&tree[0], &pending[0], 1, 0, base, n, left, i64(right), &accumulated)
			result |= i64(boundary) << u32(5 * query_index)
			query_index += 1
		}
	}
	return result
}
