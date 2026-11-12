module dynamic_sequence_range_affine_range_sum

const modulus = i64(998244353)
const max_n = 32
const max_q = 32
const max_nodes = 64
const max_input = usize(195)

struct Node {
	mut:
	left int = -1
	right int = -1
	size int = 1
	value i64
	sum i64
	mul i64 = 1
	add i64
	priority u64
	reversed bool
}
struct Operation { kind int; left int; right int; node int; mul i64; add i64 }

fn priority_for(id int) u64 {
	mut state := i64(1)
	for _ in 0 .. (id + 1) { state = (state * 48271) % 2147483647 }
	return u64(state)
}
fn node_size(nodes [max_nodes]Node, x int) int { if x < 0 { return 0 }; return nodes[x].size }
fn node_sum(nodes [max_nodes]Node, x int) i64 { if x < 0 { return 0 }; return nodes[x].sum }
fn higher(nodes [max_nodes]Node, a int, b int) bool {
	if nodes[a].priority != nodes[b].priority { return nodes[a].priority > nodes[b].priority }
	return a > b
}
fn pull(mut nodes [max_nodes]Node, x int) {
	nodes[x].size = 1 + node_size(nodes, nodes[x].left) + node_size(nodes, nodes[x].right)
	nodes[x].sum = (nodes[x].value + node_sum(nodes, nodes[x].left) + node_sum(nodes, nodes[x].right)) % modulus
}
fn affine(mut nodes [max_nodes]Node, x int, m i64, a i64) {
	if x < 0 { return }
	nodes[x].value = (m * nodes[x].value + a) % modulus
	nodes[x].sum = (m * nodes[x].sum + a * i64(nodes[x].size)) % modulus
	nodes[x].mul = (m * nodes[x].mul) % modulus
	nodes[x].add = (m * nodes[x].add + a) % modulus
}
fn reverse_node(mut nodes [max_nodes]Node, x int) {
	if x < 0 { return }
	left := nodes[x].left
	nodes[x].left = nodes[x].right
	nodes[x].right = left
	nodes[x].reversed = !nodes[x].reversed
}
fn push(mut nodes [max_nodes]Node, x int) {
	if nodes[x].mul != 1 || nodes[x].add != 0 {
		affine(mut nodes, nodes[x].left, nodes[x].mul, nodes[x].add)
		affine(mut nodes, nodes[x].right, nodes[x].mul, nodes[x].add)
		nodes[x].mul = 1
		nodes[x].add = 0
	}
	if nodes[x].reversed {
		reverse_node(mut nodes, nodes[x].left)
		reverse_node(mut nodes, nodes[x].right)
		nodes[x].reversed = false
	}
}
fn split(mut nodes [max_nodes]Node, root int, count int) (int, int) {
	if root < 0 { return -1, -1 }
	push(mut nodes, root)
	if node_size(nodes, nodes[root].left) >= count {
		a, b := split(mut nodes, nodes[root].left, count)
		nodes[root].left = b
		pull(mut nodes, root)
		return a, root
	}
	a, b := split(mut nodes, nodes[root].right, count - node_size(nodes, nodes[root].left) - 1)
	nodes[root].right = a
	pull(mut nodes, root)
	return root, b
}
fn merge(mut nodes [max_nodes]Node, a int, b int) int {
	if a < 0 { return b }
	if b < 0 { return a }
	if higher(nodes, a, b) {
		push(mut nodes, a)
		nodes[a].right = merge(mut nodes, nodes[a].right, b)
		pull(mut nodes, a)
		return a
	}
	push(mut nodes, b)
	nodes[b].left = merge(mut nodes, a, nodes[b].left)
	pull(mut nodes, b)
	return b
}
fn put64(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for j in 0 .. 8 { unsafe { output[offset + j] = u8((bits >> (8*j)) & 255) } }
}

@[export: 'dynamic_sequence_range_affine_range_sum']
pub fn dynamic_sequence_range_affine_range_sum(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > max_input { return -1 }
	nv := unsafe { input[0] }; qv := unsafe { input[1] }
	if nv < 0 || nv > max_n || qv < 0 || qv > max_q { return -1 }
	n := int(nv); q := int(qv); mut offset := 2
	if int(length) < 2+n { return -1 }
	mut nodes := [max_nodes]Node{}
	for i in 0 .. n {
		value := unsafe { input[offset] }; offset++
		if value < 0 || value >= modulus { return -1 }
		nodes[i] = Node{left: -1, right: -1, size: 1, value: value, sum: value, mul: 1, priority: priority_for(i)}
	}
	mut ops := [max_q]Operation{}; mut current := n; mut node_count := n; mut query_count := 0
	for i in 0 .. q {
		if offset >= int(length) { return -1 }
		tag := unsafe { input[offset] }; offset++
		if tag < 0 || tag > 4 { return -1 }
		mut op := Operation{kind: int(tag), node: -1}
		if tag == 0 {
			if offset+2 > int(length) { return -1 }
			at := unsafe { input[offset] }; value := unsafe { input[offset+1] }; offset += 2
			if at < 0 || at > i64(current) || current >= max_nodes || value < 0 || value >= modulus { return -1 }
			op.left = int(at); op.node = node_count
			nodes[node_count] = Node{left: -1, right: -1, size: 1, value: value, sum: value, mul: 1, priority: priority_for(node_count)}
			node_count++; current++
		} else if tag == 1 {
			if offset >= int(length) { return -1 }
			at := unsafe { input[offset] }; offset++
			if at < 0 || at >= i64(current) { return -1 }
			op.left = int(at); current--
		} else if tag == 2 || tag == 4 {
			if offset+2 > int(length) { return -1 }
			left := unsafe { input[offset] }; right := unsafe { input[offset+1] }; offset += 2
			if left < 0 || left > right || right > i64(current) { return -1 }
			op.left = int(left); op.right = int(right)
			if tag == 4 { query_count++ }
		} else {
			if offset+4 > int(length) { return -1 }
			left := unsafe { input[offset] }; right := unsafe { input[offset+1] }; mul := unsafe { input[offset+2] }; add := unsafe { input[offset+3] }; offset += 4
			if left < 0 || left > right || right > i64(current) || mul < 0 || mul >= modulus || add < 0 || add >= modulus { return -1 }
			op.left = int(left); op.right = int(right); op.mul = mul; op.add = add
		}
		ops[i] = op
	}
	if offset != int(length) { return -1 }
	mut root := -1
	for i in 0 .. n { root = merge(mut nodes, root, i) }
	mut answers := [max_q]i64{}; mut answer_count := 0
	for i in 0 .. q {
		op := ops[i]; prefix, suffix := split(mut nodes, root, op.left)
		if op.kind == 0 { root = merge(mut nodes, merge(mut nodes, prefix, op.node), suffix); continue }
		mut middle := -1; mut tail := -1
		if op.kind == 1 { middle, tail = split(mut nodes, suffix, 1); root = merge(mut nodes, prefix, tail); continue }
		else {
			middle, tail = split(mut nodes, suffix, op.right-op.left)
			if op.kind == 2 { reverse_node(mut nodes, middle) }
			else if op.kind == 3 { affine(mut nodes, middle, op.mul, op.add) }
			else { answers[answer_count] = node_sum(nodes, middle); answer_count++ }
		}
		root = merge(mut nodes, merge(mut nodes, prefix, middle), tail)
	}
	bytes := usize(8 * query_count)
	if unsafe { output == nil } || capacity < bytes { return -2 }
	for i in 0 .. query_count { put64(mut output, 8*i, answers[i]) }
	return i64(bytes)
}
