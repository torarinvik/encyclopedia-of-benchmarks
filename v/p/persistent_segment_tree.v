const max_n = 64
const max_q = 64
const max_input = 322
const node_cap = 640
const fnv_offset = u64(14695981039346656037)
const fnv_prime = u64(1099511628211)

struct Node {
	sum i64
	left int
	right int
}

fn make_node(mut nodes []Node, mut used int, sum i64, left int, right int) int {
	if used >= node_cap { return -1 }
	index := used
	used++
	nodes[index] = Node{sum: sum, left: left, right: right}
	return index
}
fn build(mut nodes []Node, mut used int, values &i64, left int, right int) int {
	if left == right { return make_node(mut nodes, mut used, unsafe { values[left] }, -1, -1) }
	mid := left + (right - left) / 2
	a := build(mut nodes, mut used, values, left, mid)
	b := build(mut nodes, mut used, values, mid + 1, right)
	if a < 0 || b < 0 { return -1 }
	return make_node(mut nodes, mut used, nodes[a].sum + nodes[b].sum, a, b)
}
fn point_set(mut nodes []Node, mut used int, root int, left int, right int, index int, value i64) int {
	if left == right { return make_node(mut nodes, mut used, value, -1, -1) }
	mid := left + (right - left) / 2
	mut a := nodes[root].left
	mut b := nodes[root].right
	if index <= mid { a = point_set(mut nodes, mut used, a, left, mid, index, value) } else { b = point_set(mut nodes, mut used, b, mid + 1, right, index, value) }
	if a < 0 || b < 0 { return -1 }
	return make_node(mut nodes, mut used, nodes[a].sum + nodes[b].sum, a, b)
}
fn range_sum(nodes []Node, node int, left int, right int, ql int, qr int) i64 {
	if ql <= left && right <= qr { return nodes[node].sum }
	mid := left + (right - left) / 2
	mut total := i64(0)
	if ql <= mid { total += range_sum(nodes, nodes[node].left, left, mid, ql, qr) }
	if qr > mid { total += range_sum(nodes, nodes[node].right, mid + 1, right, ql, qr) }
	return total
}
fn hash_word(mut hash u64, value i64) u64 {
	bits := u64(value)
	for shift in 0 .. 8 { hash = (hash ^ u64(u8(bits >> (shift * 8)))) * fnv_prime }
	return hash
}

@[export: 'persistent_segment_tree']
pub fn persistent_segment_tree(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 3 || length > max_input { return -1 }
	n64 := unsafe { input[0] }
	q64 := unsafe { input[1] }
	if n64 < 1 || n64 > max_n || q64 < 0 || q64 > max_q { return -1 }
	n := int(n64)
	q := int(q64)
	if int(length) != 2 + n + 4 * q { return -1 }
	for i in 0 .. n {
		value := unsafe { input[2 + i] }
		if value < -1000 || value > 1000 { return -1 }
	}
	mut nodes := []Node{len: node_cap}
	mut used := 0
	mut roots := [max_q + 1]int{}
	roots[0] = build(mut nodes, mut used, unsafe { &input[2] }, 0, n - 1)
	if roots[0] < 0 { return -1 }
	mut version_count := 1
	mut query_count := 0
	mut query_sums := [max_q]i64{}
	mut offset := 2 + n
	for _ in 0 .. q {
		op := unsafe { input[offset] }
		a := unsafe { input[offset + 1] }
		b := unsafe { input[offset + 2] }
		c := unsafe { input[offset + 3] }
		offset += 4
		if op == 0 {
			if a < 0 || a >= i64(version_count) || b < 0 || b >= n64 || c < -1000 || c > 1000 { return -1 }
			next := point_set(mut nodes, mut used, roots[int(a)], 0, n - 1, int(b), c)
			if next < 0 { return -1 }
			roots[version_count] = next
			version_count++
		} else if op == 1 {
			if a < 0 || a >= i64(version_count) || b < 0 || c < b || c >= n64 { return -1 }
			query_sums[query_count] = range_sum(nodes, roots[int(a)], 0, n - 1, int(b), int(c))
			query_count++
		} else { return -1 }
	}
	mut hash := hash_word(fnv_offset, i64(version_count))
	hash = hash_word(hash, i64(query_count))
	for i in 0 .. query_count { hash = hash_word(hash, query_sums[i]) }
	return i64(hash & u64(0x7fffffffffffffff))
}
