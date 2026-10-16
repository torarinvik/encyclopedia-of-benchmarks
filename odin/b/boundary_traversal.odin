package boundary_traversal

import "core:c"

MAX_N :: 100

validate :: proc "contextless" (nodes: [^]i64, n: c.size_t, node: i64,
        seen: [^]bool, reached: ^c.size_t) -> bool {
	if node == -1 do return true
	if node < 0 || u64(node) >= u64(n) do return false
	i := c.size_t(node)
	if seen[i] do return false
	seen[i] = true
	reached^ += 1
	v, l, r := nodes[3*i], nodes[3*i+1], nodes[3*i+2]
	if v < -2147483648 || v > 2147483647 || l < -1 || r < -1 ||
		(l >= 0 && u64(l) >= u64(n)) || (r >= 0 && u64(r) >= u64(n)) {
		return false
	}
	return validate(nodes, n, l, seen, reached) && validate(nodes, n, r, seen, reached)
}

is_leaf :: proc "contextless" (nodes: [^]i64, i: c.size_t) -> bool {
	return nodes[3*i+1] == -1 && nodes[3*i+2] == -1
}

emit_leaves :: proc "contextless" (nodes: [^]i64, node: i64, out: [^]i64,
		used: ^c.size_t) {
	if node == -1 do return
	i := c.size_t(node)
	if is_leaf(nodes, i) {
		out[used^] = nodes[3*i]
		used^ += 1
		return
	}
	emit_leaves(nodes, nodes[3*i+1], out, used)
	emit_leaves(nodes, nodes[3*i+2], out, used)
}

@(export)
boundary_traversal :: proc "c" (nodes: [^]i64, n: c.size_t, root: i64,
		out: [^]i64, capacity: c.size_t) -> i64 {
	if n > MAX_N || capacity < n do return -1
	if n == 0 {
		if root == -1 do return 0
		return -1
	}
	if nodes == nil || out == nil || root < 0 || u64(root) >= u64(n) do return -1
	seen: [MAX_N]bool
	reached: c.size_t = 0
	if !validate(nodes, n, root, &seen[0], &reached) || reached != n do return -1
	used: c.size_t = 0
	ri := c.size_t(root)
	if !is_leaf(nodes, ri) {
		out[used] = nodes[3*ri]
		used += 1
	}
	cur := nodes[3*ri+1]
	if cur == -1 && nodes[3*ri+2] != -1 do cur = nodes[3*ri+2]
	for cur != -1 {
		i := c.size_t(cur)
		if !is_leaf(nodes, i) {
			out[used] = nodes[3*i]
			used += 1
		}
		if nodes[3*i+1] != -1 {
			cur = nodes[3*i+1]
		} else {
			cur = nodes[3*i+2]
		}
	}
	emit_leaves(nodes, root, out, &used)
	if nodes[3*ri+2] != -1 && nodes[3*ri+1] == -1 do return i64(used)
	right: [MAX_N]i64
	rn: c.size_t = 0
	cur = nodes[3*ri+2]
	for cur != -1 {
		i := c.size_t(cur)
		if !is_leaf(nodes, i) {
			right[rn] = nodes[3*i]
			rn += 1
		}
		if nodes[3*i+2] != -1 {
			cur = nodes[3*i+2]
		} else {
			cur = nodes[3*i+1]
		}
	}
	for rn > 0 {
		rn -= 1
		out[used] = right[rn]
		used += 1
	}
	return i64(used)
}
