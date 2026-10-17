module persistent_seg_tree_lazy_prop

const max_n = 64
const max_q = 64
const max_input = 323
const node_cap = 16384
const fnv_offset = u64(0xcbf29ce484222325)
const fnv_prime = u64(0x100000001b3)

struct Node {
	sum i64
	prop i64
	left int
	right int
}

fn make_node(mut nodes []Node, mut used int, sum i64, prop i64, left int, right int) int {
	if used >= node_cap { return -1 }
	index := used
	used++
	nodes[index] = Node{sum: sum, prop: prop, left: left, right: right}
	return index
}

fn clone_node(mut nodes []Node, mut used int, source int) int {
	if source < 0 || used >= node_cap { return -1 }
	index := used
	used++
	nodes[index] = nodes[source]
	return index
}

fn push_lazy(mut nodes []Node, mut used int, node int, left int, right int) bool {
	prop := nodes[node].prop
	if prop == 0 { return true }
	nodes[node].sum += i64(right - left + 1) * prop
	if left != right {
		left_child := nodes[node].left
		right_child := nodes[node].right
		new_left := clone_node(mut nodes, mut used, left_child)
		new_right := clone_node(mut nodes, mut used, right_child)
		if new_left < 0 || new_right < 0 { return false }
		nodes[node].left = new_left
		nodes[node].right = new_right
		nodes[new_left].prop += prop
		nodes[new_right].prop += prop
	}
	nodes[node].prop = 0
	return true
}

fn build(mut nodes []Node, mut used int, values &i64, left int, right int) int {
	if left == right { return make_node(mut nodes, mut used, unsafe { values[left] }, 0, -1, -1) }
	mid := left + (right - left) / 2
	a := build(mut nodes, mut used, values, left, mid)
	b := build(mut nodes, mut used, values, mid + 1, right)
	if a < 0 || b < 0 { return -1 }
	return make_node(mut nodes, mut used, nodes[a].sum + nodes[b].sum, 0, a, b)
}

fn range_add(mut nodes []Node, mut used int, current int, left int, right int,
	ql int, qr int, delta i64) int {
	if !push_lazy(mut nodes, mut used, current, left, right) { return -1 }
	if left >= ql && right <= qr {
		copy := clone_node(mut nodes, mut used, current)
		if copy < 0 { return -1 }
		nodes[copy].prop += delta
		if !push_lazy(mut nodes, mut used, copy, left, right) { return -1 }
		return copy
	}
	if left > qr || right < ql { return current }
	copy := make_node(mut nodes, mut used, 0, 0, -1, -1)
	if copy < 0 { return -1 }
	mid := left + (right - left) / 2
	left_child := nodes[current].left
	right_child := nodes[current].right
	a := range_add(mut nodes, mut used, left_child, left, mid, ql, qr, delta)
	b := range_add(mut nodes, mut used, right_child, mid + 1, right, ql, qr, delta)
	if a < 0 || b < 0 { return -1 }
	nodes[copy].left = a
	nodes[copy].right = b
	nodes[copy].sum = nodes[a].sum + nodes[b].sum
	return copy
}

fn range_sum(mut nodes []Node, mut used int, node int, left int, right int,
	ql int, qr int, mut ok bool) i64 {
	if !push_lazy(mut nodes, mut used, node, left, right) { ok = false; return 0 }
	if right < ql || qr < left { return 0 }
	if ql <= left && right <= qr { return nodes[node].sum }
	mid := left + (right - left) / 2
	left_child := nodes[node].left
	right_child := nodes[node].right
	a := range_sum(mut nodes, mut used, left_child, left, mid, ql, qr, mut ok)
	if !ok { return 0 }
	b := range_sum(mut nodes, mut used, right_child, mid + 1, right, ql, qr, mut ok)
	return a + b
}

fn hash_word(mut hash u64, value i64) u64 {
	bits := u64(value)
	for shift in 0 .. 8 { hash = (hash ^ u64(u8(bits >> (shift * 8)))) * fnv_prime }
	return hash
}

@[export: 'persistent_seg_tree_lazy_prop']
pub fn persistent_seg_tree_lazy_prop(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 2 || length > max_input { return -1 }
	unsafe {
		n64 := input[0]
		q64 := input[1]
		if n64 < 1 || n64 > max_n || q64 < 0 || q64 > max_q { return -1 }
		n := int(n64)
		q := int(q64)
		if int(length) != 2 + n + 4 * q { return -1 }
		for i in 0 .. n {
			if input[2 + i] < -1000 || input[2 + i] > 1000 { return -1 }
		}

		mut nodes := []Node{len: node_cap}
		mut used := 0
		mut roots := [max_q + 1]int{}
		roots[0] = build(mut nodes, mut used, &input[2], 0, n - 1)
		if roots[0] < 0 { return -1 }
		mut version_count := 1
		mut query_count := 0
		mut query_sums := [max_q]i64{}
		mut offset := 2 + n
		for _ in 0 .. q {
			op := input[offset]
			a := input[offset + 1]
			b := input[offset + 2]
			c := input[offset + 3]
			offset += 4
			if op == 0 {
				if a < 0 || a > b || b >= n64 || c < -1000 || c > 1000 { return -1 }
				next := range_add(mut nodes, mut used, roots[version_count - 1], 0, n - 1, int(a), int(b), c)
				if next < 0 { return -1 }
				roots[version_count] = next
				version_count++
			} else if op == 1 {
				if a < 0 || a >= i64(version_count) || b < 0 || c < b || c >= n64 { return -1 }
				mut ok := true
				query_sums[query_count] = range_sum(mut nodes, mut used, roots[int(a)], 0, n - 1,
					int(b), int(c), mut ok)
				if !ok { return -1 }
				query_count++
			} else { return -1 }
		}

		mut hash := hash_word(fnv_offset, i64(version_count))
		hash = hash_word(hash, i64(query_count))
		for i in 0 .. query_count { hash = hash_word(hash, query_sums[i]) }
		return i64(hash & u64(0x7fffffffffffffff))
	}
}
