package dynamic_sequence_range_affine_range_sum

import "core:c"

Mod :: i64(998244353)
Max_N :: 32
Max_Q :: 32
Max_Nodes :: 64
Max_Input :: 195
None_Node :: -1

Node :: struct { left, right, size: int, value, sum, mul, add: i64, priority: u64, reversed: bool }
Operation :: struct { kind, left, right, node: int, mul, add: i64 }

priority_for :: proc(id: int) -> u64 {
	state: i64 = 1
	for _ := 0; _ <= id; _ += 1 { state = (state * 48271) % 2147483647 }
	return u64(state)
}
node_size :: proc(t: ^[Max_Nodes]Node, x: int) -> int { if x < 0 { return 0 }; return t[x].size }
node_sum :: proc(t: ^[Max_Nodes]Node, x: int) -> i64 { if x < 0 { return 0 }; return t[x].sum }
higher :: proc(t: ^[Max_Nodes]Node, a, b: int) -> bool {
	if t[a].priority != t[b].priority { return t[a].priority > t[b].priority }
	return a > b
}
pull :: proc(t: ^[Max_Nodes]Node, x: int) {
	t[x].size = 1 + node_size(t, t[x].left) + node_size(t, t[x].right)
	t[x].sum = (t[x].value + node_sum(t, t[x].left) + node_sum(t, t[x].right)) % Mod
}
affine :: proc(t: ^[Max_Nodes]Node, x: int, m, a: i64) {
	if x < 0 { return }
	t[x].value = (m*t[x].value + a) % Mod
	t[x].sum = (m*t[x].sum + a*i64(t[x].size)) % Mod
	t[x].mul = (m*t[x].mul) % Mod
	t[x].add = (m*t[x].add + a) % Mod
}
reverse_node :: proc(t: ^[Max_Nodes]Node, x: int) {
	if x < 0 { return }
	left := t[x].left; t[x].left = t[x].right; t[x].right = left; t[x].reversed = !t[x].reversed
}
push :: proc(t: ^[Max_Nodes]Node, x: int) {
	if t[x].mul != 1 || t[x].add != 0 { affine(t, t[x].left, t[x].mul, t[x].add); affine(t, t[x].right, t[x].mul, t[x].add); t[x].mul = 1; t[x].add = 0 }
	if t[x].reversed { reverse_node(t, t[x].left); reverse_node(t, t[x].right); t[x].reversed = false }
}
split :: proc(t: ^[Max_Nodes]Node, root, count: int) -> (int, int) {
	if root < 0 { return -1, -1 }
	push(t, root)
	if node_size(t, t[root].left) >= count {
		a, b := split(t, t[root].left, count); t[root].left = b; pull(t, root); return a, root
	}
	a, b := split(t, t[root].right, count-node_size(t, t[root].left)-1); t[root].right = a; pull(t, root); return root, b
}
merge :: proc(t: ^[Max_Nodes]Node, a, b: int) -> int {
	if a < 0 { return b }; if b < 0 { return a }
	if higher(t, a, b) { push(t, a); t[a].right = merge(t, t[a].right, b); pull(t, a); return a }
	push(t, b); t[b].left = merge(t, a, t[b].left); pull(t, b); return b
}
put64 :: proc(output: [^]u8, pos: int, value: i64) {
	bits := u64(value)
	for j := 0; j < 8; j += 1 { output[pos+j] = u8((bits >> (8*j)) & 255) }
}

@(export)
dynamic_sequence_range_affine_range_sum :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > c.size_t(Max_Input) do return -1
	nv, qv := input[0], input[1]
	if nv < 0 || nv > i64(Max_N) || qv < 0 || qv > i64(Max_Q) do return -1
	n, q := int(nv), int(qv); offset := 2
	if int(length) < 2+n do return -1
	nodes: [Max_Nodes]Node
	for i := 0; i < n; i += 1 {
		value := input[offset]; offset += 1
		if value < 0 || value >= Mod do return -1
		nodes[i] = {-1, -1, 1, value, value, 1, 0, priority_for(i), false}
	}
	ops: [Max_Q]Operation; current, node_count, query_count := n, n, 0
	for i := 0; i < q; i += 1 {
		if offset >= int(length) do return -1
		tag := input[offset]; offset += 1
		if tag < 0 || tag > 4 do return -1
		op := Operation{int(tag), 0, 0, -1, 0, 0}
		if tag == 0 {
			if offset+2 > int(length) do return -1
			at, value := input[offset], input[offset+1]; offset += 2
			if at < 0 || at > i64(current) || current >= Max_Nodes || value < 0 || value >= Mod do return -1
			op.left = int(at); op.node = node_count
			nodes[node_count] = {-1, -1, 1, value, value, 1, 0, priority_for(node_count), false}
			node_count += 1; current += 1
		} else if tag == 1 {
			if offset >= int(length) do return -1
			at := input[offset]; offset += 1
			if at < 0 || at >= i64(current) do return -1
			op.left = int(at); current -= 1
		} else if tag == 2 || tag == 4 {
			if offset+2 > int(length) do return -1
			left, right := input[offset], input[offset+1]; offset += 2
			if left < 0 || left > right || right > i64(current) do return -1
			op.left, op.right = int(left), int(right)
			if tag == 4 { query_count += 1 }
		} else {
			if offset+4 > int(length) do return -1
			left, right, mul, add := input[offset], input[offset+1], input[offset+2], input[offset+3]; offset += 4
			if left < 0 || left > right || right > i64(current) || mul < 0 || mul >= Mod || add < 0 || add >= Mod do return -1
			op.left, op.right, op.mul, op.add = int(left), int(right), mul, add
		}
		ops[i] = op
	}
	if offset != int(length) do return -1
	root := -1
	for i := 0; i < n; i += 1 { root = merge(&nodes, root, i) }
	answers: [Max_Q]i64; answer_count := 0
	for i := 0; i < q; i += 1 {
		op := ops[i]; prefix, suffix := split(&nodes, root, op.left)
		if op.kind == 0 { root = merge(&nodes, merge(&nodes, prefix, op.node), suffix); continue }
		middle, tail: int
		if op.kind == 1 { middle, tail = split(&nodes, suffix, 1); root = merge(&nodes, prefix, tail); continue }
		else {
			middle, tail = split(&nodes, suffix, op.right-op.left)
			if op.kind == 2 { reverse_node(&nodes, middle) }
			else if op.kind == 3 { affine(&nodes, middle, op.mul, op.add) }
			else { answers[answer_count] = node_sum(&nodes, middle); answer_count += 1 }
		}
		root = merge(&nodes, merge(&nodes, prefix, middle), tail)
	}
	bytes := c.size_t(8 * query_count)
	if output == nil || capacity < bytes do return -2
	for i := 0; i < query_count; i += 1 { put64(output, 8*i, answers[i]) }
	return i64(bytes)
}
