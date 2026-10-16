module wavelet_tree

const max_n = 64
const max_q = 128
const max_nodes = 768

struct WaveletNode {
	mut:
	low i64
	high i64
	left int
	right int
	prefix [max_n + 1]int
}

struct WaveletTree {
	mut:
		nodes [max_nodes]WaveletNode
		used int
}

fn build(mut tree WaveletTree, values []i64, low i64, high i64) int {
	id := tree.used
	tree.used++
	tree.nodes[id].low = low
	tree.nodes[id].high = high
	tree.nodes[id].left = -1
	tree.nodes[id].right = -1
	tree.nodes[id].prefix[0] = 0
	if low == high || values.len == 0 { return id }
	mid := low + (high - low) / 2
	mut left_values := []i64{}
	mut right_values := []i64{}
	for i, value in values {
		if value <= mid { left_values << value } else { right_values << value }
		tree.nodes[id].prefix[i + 1] = left_values.len
	}
	if left_values.len > 0 { tree.nodes[id].left = build(mut tree, left_values, low, mid) }
	if right_values.len > 0 { tree.nodes[id].right = build(mut tree, right_values, mid + 1, high) }
	return id
}

fn rank_prefix(tree &WaveletTree, node_id int, value i64, count int) i64 {
	if node_id < 0 || count == 0 { return 0 }
	node := tree.nodes[node_id]
	if node.low == node.high { return if node.low == value { i64(count) } else { i64(0) } }
	mid := node.low + (node.high - node.low) / 2
	left_count := node.prefix[count]
	if value <= mid { return rank_prefix(tree, node.left, value, left_count) }
	return rank_prefix(tree, node.right, value, count - left_count)
}

fn quantile(tree &WaveletTree, node_id int, left int, right int, k int) i64 {
	node := tree.nodes[node_id]
	if node.low == node.high { return node.low }
	left_before, left_after := node.prefix[left], node.prefix[right]
	in_left := left_after - left_before
	if k < in_left { return quantile(tree, node.left, left_before, left_after, k) }
	return quantile(tree, node.right, left - left_before, right - left_after, k - in_left)
}

fn range_count(tree &WaveletTree, node_id int, left int, right int, low i64, high i64) i64 {
	if node_id < 0 || left >= right { return 0 }
	node := tree.nodes[node_id]
	if high < node.low || low > node.high { return 0 }
	if low <= node.low && node.high <= high { return i64(right - left) }
	if node.low == node.high { return 0 }
	left_before, left_after := node.prefix[left], node.prefix[right]
	return range_count(tree, node.left, left_before, left_after, low, high) + range_count(tree, node.right, left - left_before, right - left_after, low, high)
}

@[export: 'wavelet_tree_benchmark']
pub fn wavelet_tree_benchmark(values &i64, length usize) i64 {
	if length < 3 || length > max_n + 2 + 5 * max_q { return -1 }
	if unsafe { values == nil } { return -1 }
	if unsafe { values[0] < 1 || values[0] > i64(max_n) } { return -1 }
	n := int(unsafe { values[0] })
	if length < usize(n + 2) { return -1 }
	mut data := [max_n]i64{}
	mut low, mut high := unsafe { values[1] }, unsafe { values[1] }
	for i in 0 .. n {
		data[i] = unsafe { values[i + 1] }
		if data[i] < -1000 || data[i] > 1000 { return -1 }
		if data[i] < low { low = data[i] }
		if data[i] > high { high = data[i] }
	}
	q_value := unsafe { values[n + 1] }
	if q_value < 0 || q_value > i64(max_q) { return -1 }
	q := int(q_value)
	if length != usize(n + 2 + 5 * q) { return -1 }
	mut tree := WaveletTree{}
	root := build(mut tree, data[..n], low, high)
	mut total := i64(0)
	for j in 0 .. q {
		p := n + 2 + 5 * j
		op := unsafe { values[p] }
		a := unsafe { values[p + 1] }
		b := unsafe { values[p + 2] }
		c := unsafe { values[p + 3] }
		d := unsafe { values[p + 4] }
		mut answer := i64(0)
		if op == 0 {
			if a < -1000 || a > 1000 || b < -1 || b >= i64(n) { return -1 }
			answer = rank_prefix(&tree, root, a, int(b + 1))
		} else if op == 1 {
			if a < 0 || b < a || b >= i64(n) || c < 0 || c > b - a { return -1 }
			answer = quantile(&tree, root, int(a), int(b + 1), int(c))
		} else if op == 2 {
			if a < 0 || b < a || b >= i64(n) || c > d || c < -1000 || d > 1000 { return -1 }
			answer = range_count(&tree, root, int(a), int(b + 1), c, d)
		} else { return -1 }
		total += i64(j + 1) * (answer + 1000001)
	}
	return total
}
