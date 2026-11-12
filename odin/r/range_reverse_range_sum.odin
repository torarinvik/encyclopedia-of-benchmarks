package range_reverse_range_sum

import "core:c"

Max_N :: 64
Max_Q :: 32
Max_Input :: 163

Node :: struct { left, right, size: int, value, sum: i64, priority: u64, reversed: bool }
Operation :: struct { kind, left, right: int }

priority_for :: proc(index: int) -> u64 {
	state: i64 = 1
	for _ := 0; _ <= index; _ += 1 { state = (state * 48271) % 2147483647 }
	return u64(state)
}
node_size :: proc(t: ^[Max_N]Node, x: int) -> int { if x < 0 { return 0 }; return t[x].size }
node_sum :: proc(t: ^[Max_N]Node, x: int) -> i64 { if x < 0 { return 0 }; return t[x].sum }
higher :: proc(t: ^[Max_N]Node, a, b: int) -> bool {
	if t[a].priority != t[b].priority { return t[a].priority > t[b].priority }
	return a > b
}
pull :: proc(t: ^[Max_N]Node, x: int) {
	t[x].size = 1 + node_size(t, t[x].left) + node_size(t, t[x].right)
	t[x].sum = t[x].value + node_sum(t, t[x].left) + node_sum(t, t[x].right)
}
reverse_node :: proc(t: ^[Max_N]Node, x: int) {
	if x < 0 { return }
	left := t[x].left; t[x].left = t[x].right; t[x].right = left; t[x].reversed = !t[x].reversed
}
push :: proc(t: ^[Max_N]Node, x: int) {
	if !t[x].reversed { return }
	reverse_node(t, t[x].left); reverse_node(t, t[x].right); t[x].reversed = false
}
split :: proc(t: ^[Max_N]Node, root, count: int) -> (int, int) {
	if root < 0 { return -1, -1 }
	push(t, root)
	if node_size(t, t[root].left) >= count {
		a, b := split(t, t[root].left, count); t[root].left = b; pull(t, root); return a, root
	}
	a, b := split(t, t[root].right, count - node_size(t, t[root].left) - 1)
	t[root].right = a; pull(t, root); return root, b
}
merge :: proc(t: ^[Max_N]Node, a, b: int) -> int {
	if a < 0 { return b }; if b < 0 { return a }
	if higher(t, a, b) { push(t, a); t[a].right = merge(t, t[a].right, b); pull(t, a); return a }
	push(t, b); t[b].left = merge(t, a, t[b].left); pull(t, b); return b
}
put64 :: proc(output: [^]u8, pos: int, value: i64) {
	bits := u64(value)
	for j := 0; j < 8; j += 1 { output[pos+j] = u8((bits >> (8*j)) & 255) }
}

@(export)
range_reverse_range_sum :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > c.size_t(Max_Input) do return -1
	nv, qv := input[0], input[1]
	if nv < 0 || nv > i64(Max_N) || qv < 0 || qv > i64(Max_Q) do return -1
	n, q := int(nv), int(qv); offset := 2
	if int(length) < 2+n do return -1
	nodes: [Max_N]Node
	for i := 0; i < n; i += 1 {
		value := input[offset]; offset += 1
		if value < 0 || value > 1_000_000_000 do return -1
		nodes[i] = {-1, -1, 1, value, value, priority_for(i), false}
	}
	ops: [Max_Q]Operation; query_count := 0
	for i := 0; i < q; i += 1 {
		if offset+3 > int(length) do return -1
		kind, left, right := input[offset], input[offset+1], input[offset+2]; offset += 3
		if (kind != 0 && kind != 1) || left < 0 || left > right || right > nv do return -1
		ops[i] = {int(kind), int(left), int(right)}
		if kind == 1 { query_count += 1 }
	}
	if offset != int(length) do return -1
	root := -1
	for i := 0; i < n; i += 1 { root = merge(&nodes, root, i) }
	answers: [Max_Q]i64; answer_count := 0
	for i := 0; i < q; i += 1 {
		op := ops[i]; prefix, suffix := split(&nodes, root, op.right); prefix, middle := split(&nodes, prefix, op.left)
		if op.kind == 0 { reverse_node(&nodes, middle) }
		else { answers[answer_count] = node_sum(&nodes, middle); answer_count += 1 }
		root = merge(&nodes, merge(&nodes, prefix, middle), suffix)
	}
	bytes := c.size_t(8 * query_count)
	if output == nil || capacity < bytes do return -2
	for i := 0; i < query_count; i += 1 { put64(output, 8*i, answers[i]) }
	return i64(bytes)
}
