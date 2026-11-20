package schieber_vishkin_lca

import "core:c"

MAX_NODES :: 256
MAX_QUERIES :: 1024
MAX_ARCS :: 510
MAX_INPUT :: 4 + 2 * (MAX_NODES - 1) + 2 * MAX_QUERIES

lowbit :: proc "contextless" (x: u32) -> u32 { return x & (0 - x) }
highbit :: proc "contextless" (x: u32) -> u32 {
	rest := x
	bit: u32 = 0
	for rest != 0 { bit = rest; rest >>= 1 }
	return bit
}

@(export)
schieber_vishkin_lca :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 4 || length > c.size_t(MAX_INPUT + 1) do return -1
	if input[0] < 1 || input[0] > MAX_NODES do return -1
	n := int(input[0])
	if input[1] < 0 || input[1] >= i64(n) || input[2] != i64(n - 1) ||
		input[3] < 0 || input[3] > MAX_QUERIES do return -1
	m, q := int(input[2]), int(input[3])
	query_offset := 4 + 2 * m
	if length != c.size_t(query_offset + 2 * q) do return -1
	root := int(input[1])

	head := [MAX_NODES]int{}
	arc_to, arc_next := [MAX_ARCS]int{}
	parent, order, stack_node, stack_arc, path_parent := [MAX_NODES]int{}
	preorder := [MAX_NODES]uint{}
	inlabel, ascendant := [MAX_NODES]u32{}
	answers := [MAX_QUERIES]u8{}
	for node := 0; node < n; node += 1 { head[node] = -1; parent[node] = -2 }
	arcs := 0
	for edge := 0; edge < m; edge += 1 {
		a_value, b_value := input[4 + 2 * edge], input[5 + 2 * edge]
		if a_value < 0 || a_value >= i64(n) || b_value < 0 || b_value >= i64(n) || a_value == b_value do return -1
		a, b := int(a_value), int(b_value)
		arc_to[arcs] = b; arc_next[arcs] = head[a]; head[a] = arcs; arcs += 1
		arc_to[arcs] = a; arc_next[arcs] = head[b]; head[b] = arcs; arcs += 1
	}
	for query := 0; query < q; query += 1 {
		for side := 0; side < 2; side += 1 {
			node := input[query_offset + 2 * query + side]
			if node < 0 || node >= i64(n) do return -1
		}
	}

	reached, top := 1, 1
	parent[root] = -1; preorder[root] = 1; order[0] = root
	stack_node[0] = root; stack_arc[0] = head[root]
	for top > 0 {
		slot := top - 1
		node, arc := stack_node[slot], stack_arc[slot]
		if arc < 0 { top -= 1; continue }
		stack_arc[slot] = arc_next[arc]
		neighbor := arc_to[arc]
		if neighbor == parent[node] do continue
		if parent[neighbor] != -2 do return -1
		parent[neighbor] = node; preorder[neighbor] = uint(reached + 1); order[reached] = neighbor; reached += 1
		stack_node[top] = neighbor; stack_arc[top] = head[neighbor]; top += 1
	}
	if reached != n do return -1
	if capacity < c.size_t(q) || (q > 0 && output == nil) do return -2

	for node := 0; node < n; node += 1 { inlabel[node] = u32(preorder[node]) }
	for i := n; i > 1; i -= 1 {
		node := order[i - 1]; p := parent[node]
		if lowbit(inlabel[p]) < lowbit(inlabel[node]) do inlabel[p] = inlabel[node]
	}
	for pos := 0; pos < n; pos += 1 {
		node := order[pos]
		if parent[node] < 0 {
			ascendant[node] = lowbit(inlabel[node]); path_parent[preorder[node] - 1] = node
		} else {
			p := parent[node]
			ascendant[node] = ascendant[p] | lowbit(inlabel[node])
			if inlabel[node] != inlabel[p] do path_parent[preorder[node] - 1] = p
			else path_parent[preorder[node] - 1] = path_parent[preorder[p] - 1]
		}
	}
	for query := 0; query < q; query += 1 {
		u, v := int(input[query_offset + 2 * query]), int(input[query_offset + 2 * query + 1])
		lu, lv := lowbit(inlabel[u]), lowbit(inlabel[v])
		mask := highbit((inlabel[u] ^ inlabel[v]) | lu | lv) - 1
		j := lowbit(ascendant[u] & ascendant[v] & ^mask)
		if j == 0 do return -1
		x, y := u, v
		if j != lu {
			mask = highbit(ascendant[u] & (j - 1)) - 1
			index := int((preorder[u] & ^uint(mask)) | (uint(mask) + 1)) - 1
			x = path_parent[index]
		}
		if j != lv {
			mask = highbit(ascendant[v] & (j - 1)) - 1
			index := int((preorder[v] & ^uint(mask)) | (uint(mask) + 1)) - 1
			y = path_parent[index]
		}
		answer := x
		if preorder[y] < preorder[x] do answer = y
		answers[query] = u8(answer)
	}
	for query := 0; query < q; query += 1 { output[query] = answers[query] }
	return i64(q)
}
