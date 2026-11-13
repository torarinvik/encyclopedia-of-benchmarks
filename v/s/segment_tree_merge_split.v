module segment_tree_merge_split

const domain = 64
const max_q = 32
const max_roots = 33
const max_nodes = 1024
const max_input = usize(131)
const max_output = 256

struct Node {
	mut:
	left int
	right int
	total i64
}

struct Operation {
	op i64
	a i64
	b i64
	c i64
}

fn new_node(mut nodes [max_nodes]Node, mut used int) int {
	if used >= max_nodes { return -1 }
	node := used
	used++
	nodes[node] = Node{}
	return node
}

fn insert(mut nodes [max_nodes]Node, mut used int, node_value int,
	lo int, hi int, value int, amount i64) int {
	mut node := node_value
	if node == 0 {
		node = new_node(mut nodes, mut used)
		if node < 0 { return -1 }
	}
	if lo == hi {
		nodes[node].total += amount
		return node
	}
	mid := (lo + hi) / 2
	if value <= mid {
		child := insert(mut nodes, mut used, nodes[node].left, lo, mid, value, amount)
		if child < 0 { return -1 }
		nodes[node].left = child
	} else {
		child := insert(mut nodes, mut used, nodes[node].right, mid + 1, hi, value, amount)
		if child < 0 { return -1 }
		nodes[node].right = child
	}
	nodes[node].total = nodes[nodes[node].left].total + nodes[nodes[node].right].total
	return node
}

fn merge_nodes(mut nodes [max_nodes]Node, a int, b int, lo int, hi int) int {
	if a == 0 { return b }
	if b == 0 { return a }
	if lo == hi {
		nodes[a].total += nodes[b].total
		return a
	}
	mid := (lo + hi) / 2
	al, ar := nodes[a].left, nodes[a].right
	bl, br := nodes[b].left, nodes[b].right
	nodes[a].left = merge_nodes(mut nodes, al, bl, lo, mid)
	nodes[a].right = merge_nodes(mut nodes, ar, br, mid + 1, hi)
	nodes[a].total = nodes[nodes[a].left].total + nodes[nodes[a].right].total
	return a
}

fn split(mut nodes [max_nodes]Node, mut used int, node int,
	lo int, hi int, ql int, qr int) (int, int) {
	if node == 0 || qr < lo || hi < ql { return node, 0 }
	if ql <= lo && hi <= qr { return 0, node }
	mid := (lo + hi) / 2
	rl, ml := split(mut nodes, mut used, nodes[node].left, lo, mid, ql, qr)
	if rl < 0 { return -1, 0 }
	rr, mr := split(mut nodes, mut used, nodes[node].right, mid + 1, hi, ql, qr)
	if rr < 0 { return -1, 0 }
	nodes[node].left, nodes[node].right = rl, rr
	nodes[node].total = nodes[rl].total + nodes[rr].total
	mut moved := 0
	if ml != 0 || mr != 0 {
		moved = new_node(mut nodes, mut used)
		if moved < 0 { return -1, 0 }
		nodes[moved].left, nodes[moved].right = ml, mr
		nodes[moved].total = nodes[ml].total + nodes[mr].total
	}
	return node, moved
}

fn range_sum(nodes [max_nodes]Node, node int, lo int, hi int, ql int, qr int) i64 {
	if node == 0 || qr < lo || hi < ql { return 0 }
	if ql <= lo && hi <= qr { return nodes[node].total }
	mid := (lo + hi) / 2
	return range_sum(nodes, nodes[node].left, lo, mid, ql, qr) +
		range_sum(nodes, nodes[node].right, mid + 1, hi, ql, qr)
}

fn kth(nodes [max_nodes]Node, node int, lo int, hi int, k i64) i64 {
	if node == 0 || k > nodes[node].total { return -1 }
	if lo == hi { return i64(lo) }
	mid := (lo + hi) / 2
	left_node := nodes[node].left
	if k <= nodes[left_node].total { return kth(nodes, left_node, lo, mid, k) }
	return kth(nodes, nodes[node].right, mid + 1, hi, k-nodes[left_node].total)
}

fn put_i64(mut output [max_output]u8, offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 { output[offset + byte] = u8((bits >> (8 * byte)) & 255) }
}

@[export: 'segment_tree_merge_split']
pub fn segment_tree_merge_split(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > max_input { return -1 }
	if unsafe { input[0] != domain || input[1] < 0 || input[1] > max_q } { return -1 }
	q := int(unsafe { input[1] })
	if length != usize(2 + 4 * q) { return -1 }

	mut operations := [max_q]Operation{}
	mut roots_count := 1
	for i in 0 .. q {
		base := 2 + 4 * i
		op := unsafe { input[base] }
		a := unsafe { input[base + 1] }
		b := unsafe { input[base + 2] }
		c_value := unsafe { input[base + 3] }
		a_ok := a >= 0 && a < i64(roots_count)
		b_ok := b >= 0 && b < i64(roots_count)
		mut valid := false
		if op == 0 { valid = a_ok && b >= 1 && b <= domain && c_value >= 1 && c_value <= 10 }
		else if op == 1 {
			valid = a_ok && b >= 1 && b <= c_value && c_value <= domain && roots_count < max_roots
			if valid { roots_count++ }
		} else if op == 2 { valid = a_ok && b_ok && a != b && c_value == 0 }
		else if op == 3 { valid = a_ok && b >= 1 && b <= c_value && c_value <= domain }
		else if op == 4 { valid = a_ok && b >= 1 && b <= 320 && c_value == 0 }
		if !valid { return -1 }
		operations[i] = Operation{op: op, a: a, b: b, c: c_value}
	}

	mut nodes := [max_nodes]Node{}
	mut roots := [max_roots]int{}
	mut staged := [max_output]u8{}
	mut used := 1
	mut root_count := 1
	mut bytes := 0
	for i in 0 .. q {
		item := operations[i]
		a, b, c_value := int(item.a), int(item.b), int(item.c)
		if item.op == 0 {
			updated := insert(mut nodes, mut used, roots[a], 1, domain, b, item.c)
			if updated < 0 { return -1 }
			roots[a] = updated
		} else if item.op == 1 {
			remain, moved := split(mut nodes, mut used, roots[a], 1, domain, b, c_value)
			if remain < 0 || moved < 0 { return -1 }
			roots[a], roots[root_count] = remain, moved
			root_count++
		} else if item.op == 2 {
			roots[a] = merge_nodes(mut nodes, roots[a], roots[b], 1, domain)
			roots[b] = 0
		} else if item.op == 3 {
			put_i64(mut staged, bytes, range_sum(nodes, roots[a], 1, domain, b, c_value))
			bytes += 8
		} else {
			put_i64(mut staged, bytes, kth(nodes, roots[a], 1, domain, item.b))
			bytes += 8
		}
	}
	if unsafe { output == nil } || capacity < usize(bytes) { return -2 }
	for i in 0 .. bytes { unsafe { output[i] = staged[i] } }
	return i64(bytes)
}
