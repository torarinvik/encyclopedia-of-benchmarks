package segment_tree_merge_split

import "core:c"

Domain :: 64
Max_Q :: 32
Max_Roots :: 33
Max_Nodes :: 1024
Max_Input :: 131
Max_Output :: 256

Node :: struct { left, right: i32, total: i64 }
Operation :: struct { op, a, b, c: i64 }

new_node :: proc(nodes: ^[Max_Nodes]Node, used: ^int) -> i32 {
	if used^ >= Max_Nodes do return -1
	node := used^
	used^ += 1
	nodes[node] = {}
	return i32(node)
}

insert :: proc(nodes: ^[Max_Nodes]Node, used: ^int, node_value: i32,
	lo, hi, value: int, amount: i64) -> i32 {
	node := node_value
	if node == 0 {
		node = new_node(nodes, used)
		if node < 0 do return -1
	}
	index := int(node)
	if lo == hi { nodes[index].total += amount; return node }
	mid := (lo + hi) / 2
	if value <= mid {
		child := insert(nodes, used, nodes[index].left, lo, mid, value, amount)
		if child < 0 do return -1
		nodes[index].left = child
	} else {
		child := insert(nodes, used, nodes[index].right, mid + 1, hi, value, amount)
		if child < 0 do return -1
		nodes[index].right = child
	}
	nodes[index].total = nodes[int(nodes[index].left)].total + nodes[int(nodes[index].right)].total
	return node
}

merge_nodes :: proc(nodes: ^[Max_Nodes]Node, a, b: i32, lo, hi: int) -> i32 {
	if a == 0 do return b
	if b == 0 do return a
	ai, bi := int(a), int(b)
	if lo == hi { nodes[ai].total += nodes[bi].total; return a }
	mid := (lo + hi) / 2
	al, ar := nodes[ai].left, nodes[ai].right
	bl, br := nodes[bi].left, nodes[bi].right
	nodes[ai].left = merge_nodes(nodes, al, bl, lo, mid)
	nodes[ai].right = merge_nodes(nodes, ar, br, mid + 1, hi)
	nodes[ai].total = nodes[int(nodes[ai].left)].total + nodes[int(nodes[ai].right)].total
	return a
}

split :: proc(nodes: ^[Max_Nodes]Node, used: ^int, node: i32,
	lo, hi, ql, qr: int) -> (i32, i32) {
	if node == 0 || qr < lo || hi < ql { return node, 0 }
	if ql <= lo && hi <= qr { return 0, node }
	index := int(node)
	mid := (lo + hi) / 2
	rl, ml := split(nodes, used, nodes[index].left, lo, mid, ql, qr)
	if rl < 0 do return -1, 0
	rr, mr := split(nodes, used, nodes[index].right, mid + 1, hi, ql, qr)
	if rr < 0 do return -1, 0
	nodes[index].left, nodes[index].right = rl, rr
	nodes[index].total = nodes[int(rl)].total + nodes[int(rr)].total
	moved: i32 = 0
	if ml != 0 || mr != 0 {
		moved = new_node(nodes, used)
		if moved < 0 do return -1, 0
		mi := int(moved)
		nodes[mi].left, nodes[mi].right = ml, mr
		nodes[mi].total = nodes[int(ml)].total + nodes[int(mr)].total
	}
	return node, moved
}

range_sum :: proc(nodes: ^[Max_Nodes]Node, node: i32, lo, hi, ql, qr: int) -> i64 {
	if node == 0 || qr < lo || hi < ql do return 0
	index := int(node)
	if ql <= lo && hi <= qr do return nodes[index].total
	mid := (lo + hi) / 2
	return range_sum(nodes, nodes[index].left, lo, mid, ql, qr) +
		range_sum(nodes, nodes[index].right, mid + 1, hi, ql, qr)
}

kth :: proc(nodes: ^[Max_Nodes]Node, node: i32, lo, hi: int, k: i64) -> i64 {
	if node == 0 || k > nodes[int(node)].total do return -1
	if lo == hi do return i64(lo)
	index := int(node)
	mid := (lo + hi) / 2
	left_node := nodes[index].left
	if k <= nodes[int(left_node)].total do return kth(nodes, left_node, lo, mid, k)
	return kth(nodes, nodes[index].right, mid + 1, hi, k-nodes[int(left_node)].total)
}

put_i64 :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset+byte] = u8((bits >> (8*byte)) & 255) }
}

@(export)
segment_tree_merge_split :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > c.size_t(Max_Input) do return -1
	if input[0] != Domain || input[1] < 0 || input[1] > Max_Q do return -1
	q := int(input[1])
	if int(length) != 2+4*q do return -1
	operations: [Max_Q]Operation
	roots_count := 1
	for i := 0; i < q; i += 1 {
		base := 2+4*i
		op, a, b, c_value := input[base], input[base+1], input[base+2], input[base+3]
		a_ok := a >= 0 && int(a) < roots_count
		b_ok := b >= 0 && int(b) < roots_count
		valid := false
		if op == 0 { valid = a_ok && b >= 1 && b <= Domain && c_value >= 1 && c_value <= 10 }
		else if op == 1 {
			valid = a_ok && b >= 1 && b <= c_value && c_value <= Domain && roots_count < Max_Roots
			if valid { roots_count++ }
		} else if op == 2 { valid = a_ok && b_ok && a != b && c_value == 0 }
		else if op == 3 { valid = a_ok && b >= 1 && b <= c_value && c_value <= Domain }
		else if op == 4 { valid = a_ok && b >= 1 && b <= 320 && c_value == 0 }
		if !valid do return -1
		operations[i] = Operation{op, a, b, c_value}
	}

	mut nodes: [Max_Nodes]Node
	mut roots: [Max_Roots]i32
	mut staged: [Max_Output]u8
	mut used := 1
	mut root_count := 1
	mut bytes := 0
	for i := 0; i < q; i += 1 {
		item := operations[i]
		a, b, c_value := int(item.a), int(item.b), int(item.c)
		if item.op == 0 {
			updated := insert(&nodes, &used, roots[a], 1, Domain, b, item.c)
			if updated < 0 do return -1
			roots[a] = updated
		} else if item.op == 1 {
			remain, moved := split(&nodes, &used, roots[a], 1, Domain, b, c_value)
			if remain < 0 || moved < 0 do return -1
			roots[a], roots[root_count] = remain, moved
			root_count++
		} else if item.op == 2 {
			roots[a] = merge_nodes(&nodes, roots[a], roots[b], 1, Domain)
			roots[b] = 0
		} else if item.op == 3 {
			put_i64(&staged, bytes, range_sum(&nodes, roots[a], 1, Domain, b, c_value))
			bytes += 8
		} else {
			put_i64(&staged, bytes, kth(&nodes, roots[a], 1, Domain, item.b))
			bytes += 8
		}
	}
	if output == nil || capacity < c.size_t(bytes) do return -2
	for i := 0; i < bytes; i += 1 { output[i] = staged[i] }
	return i64(bytes)
}
