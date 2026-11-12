module range_reverse_range_sum

const max_n = 64
const max_q = 32
const max_input = usize(163)

struct Node {
	mut:
	left int = -1
	right int = -1
	size int = 1
	value i64
	sum i64
	priority u64
	reversed bool
}
struct Operation { kind int; left int; right int }

fn priority_for(index int) u64 {
	mut state := i64(1)
	for _ in 0 .. (index + 1) { state = (state * 48271) % 2147483647 }
	return u64(state)
}
fn node_size(nodes [max_n]Node, x int) int { if x < 0 { return 0 }; return nodes[x].size }
fn node_sum(nodes [max_n]Node, x int) i64 { if x < 0 { return 0 }; return nodes[x].sum }
fn higher(nodes [max_n]Node, a int, b int) bool {
	if nodes[a].priority != nodes[b].priority { return nodes[a].priority > nodes[b].priority }
	return a > b
}
fn pull(mut nodes [max_n]Node, x int) {
	nodes[x].size = 1 + node_size(nodes, nodes[x].left) + node_size(nodes, nodes[x].right)
	nodes[x].sum = nodes[x].value + node_sum(nodes, nodes[x].left) + node_sum(nodes, nodes[x].right)
}
fn reverse_node(mut nodes [max_n]Node, x int) {
	if x < 0 { return }
	left := nodes[x].left; nodes[x].left = nodes[x].right; nodes[x].right = left
	nodes[x].reversed = !nodes[x].reversed
}
fn push(mut nodes [max_n]Node, x int) {
	if !nodes[x].reversed { return }
	reverse_node(mut nodes, nodes[x].left); reverse_node(mut nodes, nodes[x].right)
	nodes[x].reversed = false
}
fn split(mut nodes [max_n]Node, root int, count int) (int, int) {
	if root < 0 { return -1, -1 }
	push(mut nodes, root)
	if node_size(nodes, nodes[root].left) >= count {
		a, b := split(mut nodes, nodes[root].left, count)
		nodes[root].left = b; pull(mut nodes, root); return a, root
	}
	a, b := split(mut nodes, nodes[root].right,
		count - node_size(nodes, nodes[root].left) - 1)
	nodes[root].right = a; pull(mut nodes, root); return root, b
}
fn merge(mut nodes [max_n]Node, a int, b int) int {
	if a < 0 { return b }; if b < 0 { return a }
	if higher(nodes, a, b) {
		push(mut nodes, a); nodes[a].right = merge(mut nodes, nodes[a].right, b); pull(mut nodes, a); return a
	}
	push(mut nodes, b); nodes[b].left = merge(mut nodes, a, nodes[b].left); pull(mut nodes, b); return b
}
fn put64(mut output &u8, offset int, value i64) {
	bits := u64(value)
	for j in 0 .. 8 { unsafe { output[offset + j] = u8((bits >> (8*j)) & 255) } }
}

@[export: 'range_reverse_range_sum']
pub fn range_reverse_range_sum(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > max_input { return -1 }
	nv := unsafe { input[0] }; qv := unsafe { input[1] }
	if nv < 0 || nv > max_n || qv < 0 || qv > max_q { return -1 }
	n := int(nv); q := int(qv); mut offset := 2
	if int(length) < 2+n { return -1 }
	mut nodes := [max_n]Node{}
	for i in 0 .. n {
		value := unsafe { input[offset] }; offset++
		if value < 0 || value > 1000000000 { return -1 }
		nodes[i] = Node{left: -1, right: -1, size: 1, value: value, sum: value, priority: priority_for(i)}
	}
	mut ops := [max_q]Operation{}; mut query_count := 0
	for i in 0 .. q {
		if offset+3 > int(length) { return -1 }
		kind := unsafe { input[offset] }; left := unsafe { input[offset+1] }; right := unsafe { input[offset+2] }; offset += 3
		if (kind != 0 && kind != 1) || left < 0 || left > right || right > nv { return -1 }
		ops[i] = Operation{kind: int(kind), left: int(left), right: int(right)}
		if kind == 1 { query_count++ }
	}
	if offset != int(length) { return -1 }
	mut root := -1
	for i in 0 .. n { root = merge(mut nodes, root, i) }
	mut answers := [max_q]i64{}; mut answer_count := 0
	for i in 0 .. q {
		op := ops[i]
		prefix, suffix := split(mut nodes, root, op.right)
		prefix, middle := split(mut nodes, prefix, op.left)
		if op.kind == 0 { reverse_node(mut nodes, middle) }
		else { answers[answer_count] = node_sum(nodes, middle); answer_count++ }
		root = merge(mut nodes, merge(mut nodes, prefix, middle), suffix)
	}
	bytes := usize(8 * query_count)
	if unsafe { output == nil } || capacity < bytes { return -2 }
	for i in 0 .. query_count { put64(mut output, 8*i, answers[i]) }
	return i64(bytes)
}
