package persistent_seg_tree_lazy_prop

MAX_N :: 64
MAX_Q :: 64
MAX_INPUT :: 323
NODE_CAP :: 16384
FNV_OFFSET :: u64(0xcbf29ce484222325)
FNV_PRIME :: u64(0x100000001b3)

Node :: struct { sum, prop: i64, left, right: int }

make_node :: proc "contextless" (nodes: [^]Node, used: ^int, sum, prop: i64, left, right: int) -> int {
	if used^ >= NODE_CAP do return -1
	index := used^
	used^ += 1
	nodes[index] = Node{sum, prop, left, right}
	return index
}

clone_node :: proc "contextless" (nodes: [^]Node, used: ^int, source: int) -> int {
	if source < 0 || used^ >= NODE_CAP do return -1
	index := used^
	used^ += 1
	nodes[index] = nodes[source]
	return index
}

push_lazy :: proc "contextless" (nodes: [^]Node, used: ^int, node, left, right: int) -> bool {
	prop := nodes[node].prop
	if prop == 0 do return true
	nodes[node].sum += i64(right-left+1) * prop
	if left != right {
		new_left := clone_node(nodes, used, nodes[node].left)
		new_right := clone_node(nodes, used, nodes[node].right)
		if new_left < 0 || new_right < 0 do return false
		nodes[node].left = new_left
		nodes[node].right = new_right
		nodes[new_left].prop += prop
		nodes[new_right].prop += prop
	}
	nodes[node].prop = 0
	return true
}

build :: proc "contextless" (nodes: [^]Node, used: ^int, values: [^]i64, left, right: int) -> int {
	if left == right do return make_node(nodes, used, values[left], 0, -1, -1)
	mid := left + (right-left)/2
	a := build(nodes, used, values, left, mid)
	b := build(nodes, used, values, mid+1, right)
	if a < 0 || b < 0 do return -1
	return make_node(nodes, used, nodes[a].sum+nodes[b].sum, 0, a, b)
}

range_add :: proc "contextless" (nodes: [^]Node, used: ^int, current, left, right, ql, qr: int, delta: i64) -> int {
	if !push_lazy(nodes, used, current, left, right) do return -1
	if left >= ql && right <= qr {
		copy := clone_node(nodes, used, current)
		if copy < 0 do return -1
		nodes[copy].prop += delta
		if !push_lazy(nodes, used, copy, left, right) do return -1
		return copy
	}
	if left > qr || right < ql do return current
	copy := make_node(nodes, used, 0, 0, -1, -1)
	if copy < 0 do return -1
	mid := left + (right-left)/2
	a := range_add(nodes, used, nodes[current].left, left, mid, ql, qr, delta)
	b := range_add(nodes, used, nodes[current].right, mid+1, right, ql, qr, delta)
	if a < 0 || b < 0 do return -1
	nodes[copy].left = a
	nodes[copy].right = b
	nodes[copy].sum = nodes[a].sum + nodes[b].sum
	return copy
}

range_sum :: proc "contextless" (nodes: [^]Node, used: ^int, node, left, right, ql, qr: int, ok: ^bool) -> i64 {
	if !push_lazy(nodes, used, node, left, right) { ok^ = false; return 0 }
	if right < ql || qr < left do return 0
	if ql <= left && right <= qr do return nodes[node].sum
	mid := left + (right-left)/2
	a := range_sum(nodes, used, nodes[node].left, left, mid, ql, qr, ok)
	if !ok^ do return 0
	b := range_sum(nodes, used, nodes[node].right, mid+1, right, ql, qr, ok)
	return a+b
}

hash_word :: proc "contextless" (hash: u64, value: i64) -> u64 {
	bits := u64(value)
	result := hash
	for shift := 0; shift < 64; shift += 8 { result = (result ^ u64(u8(bits >> u32(shift)))) * FNV_PRIME }
	return result
}

@(export)
persistent_seg_tree_lazy_prop :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > MAX_INPUT do return -1
	n64, q64 := input[0], input[1]
	if n64 < 1 || n64 > MAX_N || q64 < 0 || q64 > MAX_Q do return -1
	n, q := int(n64), int(q64)
	if int(length) != 2+n+4*q do return -1
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
			if a < 0 || a > b || b >= n64 || c_value < -1000 || c_value > 1000 do return -1
			next := range_add(&nodes[0], &used, roots[version_count-1], 0, n-1, int(a), int(b), c_value)
			if next < 0 do return -1
			roots[version_count] = next
			version_count += 1
		} else if op == 1 {
			if a < 0 || a >= i64(version_count) || b < 0 || c_value < b || c_value >= n64 do return -1
			ok := true
			query_sums[query_count] = range_sum(&nodes[0], &used, roots[int(a)], 0, n-1, int(b), int(c_value), &ok)
			if !ok do return -1
			query_count += 1
		} else do return -1
	}

	hash := hash_word(FNV_OFFSET, i64(version_count))
	hash = hash_word(hash, i64(query_count))
	for i := 0; i < query_count; i += 1 { hash = hash_word(hash, query_sums[i]) }
	return i64(hash & 0x7fffffffffffffff)
}
