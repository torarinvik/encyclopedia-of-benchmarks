package persistent_segment_tree

import "core:c"

MAX_N :: 64
MAX_Q :: 64
MAX_INPUT :: 322
NODE_CAP :: 640
FNV_OFFSET :: u64(0xcbf29ce484222325)
FNV_PRIME :: u64(0x100000001b3)

Node :: struct { sum: i64, left, right: int }

make_node :: proc "contextless" (nodes: [^]Node, used: ^int, sum: i64, left, right: int) -> int {
	if used^ >= NODE_CAP do return -1
	index := used^
	used^ += 1
	nodes[index] = Node{sum, left, right}
	return index
}
build :: proc "contextless" (nodes: [^]Node, used: ^int, values: [^]i64, left, right: int) -> int {
	if left == right do return make_node(nodes, used, values[left], -1, -1)
	mid := left + (right - left) / 2
	a := build(nodes, used, values, left, mid)
	b := build(nodes, used, values, mid + 1, right)
	if a < 0 || b < 0 do return -1
	return make_node(nodes, used, nodes[a].sum + nodes[b].sum, a, b)
}
point_set :: proc "contextless" (nodes: [^]Node, used: ^int, root, left, right, index: int, value: i64) -> int {
	if left == right do return make_node(nodes, used, value, -1, -1)
	mid := left + (right - left) / 2
	a, b := nodes[root].left, nodes[root].right
	if index <= mid do a = point_set(nodes, used, a, left, mid, index, value)
	else do b = point_set(nodes, used, b, mid + 1, right, index, value)
	if a < 0 || b < 0 do return -1
	return make_node(nodes, used, nodes[a].sum + nodes[b].sum, a, b)
}
range_sum :: proc "contextless" (nodes: [^]Node, node, left, right, ql, qr: int) -> i64 {
	if ql <= left && right <= qr do return nodes[node].sum
	mid := left + (right - left) / 2
	total := i64(0)
	if ql <= mid do total += range_sum(nodes, nodes[node].left, left, mid, ql, qr)
	if qr > mid do total += range_sum(nodes, nodes[node].right, mid + 1, right, ql, qr)
	return total
}
hash_word :: proc "contextless" (hash: u64, value: i64) -> u64 {
	bits := u64(value)
	result := hash
	for shift := 0; shift < 64; shift += 8 { result = (result ^ u64(u8(bits >> u32(shift)))) * FNV_PRIME }
	return result
}

@(export)
persistent_segment_tree :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 3 || length > MAX_INPUT do return -1
	n64, q64 := input[0], input[1]
	if n64 < 1 || n64 > MAX_N || q64 < 0 || q64 > MAX_Q do return -1
	n, q := int(n64), int(q64)
	if int(length) != 2 + n + 4 * q do return -1
	for i := 0; i < n; i += 1 { if input[2+i] < -1000 || input[2+i] > 1000 do return -1 }
	var nodes: [NODE_CAP]Node
	used := 0
	var roots: [MAX_Q+1]int
	roots[0] = build(&nodes[0], &used, &input[2], 0, n-1)
	if roots[0] < 0 do return -1
	version_count, query_count, offset := 1, 0, 2+n
	var query_sums: [MAX_Q]i64
	for _ := 0; _ < q; _ += 1 {
		op, a, b, c_value := input[offset], input[offset+1], input[offset+2], input[offset+3]
		offset += 4
		if op == 0 {
			if a < 0 || a >= i64(version_count) || b < 0 || b >= n64 || c_value < -1000 || c_value > 1000 do return -1
			next := point_set(&nodes[0], &used, roots[int(a)], 0, n-1, int(b), c_value)
			if next < 0 do return -1
			roots[version_count] = next
			version_count += 1
		} else if op == 1 {
			if a < 0 || a >= i64(version_count) || b < 0 || c_value < b || c_value >= n64 do return -1
			query_sums[query_count] = range_sum(&nodes[0], roots[int(a)], 0, n-1, int(b), int(c_value))
			query_count += 1
		} else do return -1
	}
	hash := hash_word(FNV_OFFSET, i64(version_count))
	hash = hash_word(hash, i64(query_count))
	for i := 0; i < query_count; i += 1 { hash = hash_word(hash, query_sums[i]) }
	return i64(hash & 0x7fffffffffffffff)
}
