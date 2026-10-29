module segment_tree_beats

const (
	max_items = 64
	max_operations = 128
	max_input_values = 2 + max_items + 4 * max_operations
	tree_size = 4 * max_items
	value_limit = i64(1_000_000)
	inf = i64(2_305_843_009_213_693_951)
	query_offset = i64(8_256_000_001)
)

struct SegmentNode {
	sum i64
	max1 i64
	max2 i64
	min1 i64
	min2 i64
	add i64
	max_count int
	min_count int
}

fn pull(mut tree [tree_size]SegmentNode, node int) {
	left := tree[2 * node]
	right := tree[2 * node + 1]
	tree[node].sum = left.sum + right.sum
	tree[node].add = 0
	if left.max1 == right.max1 {
		tree[node].max1 = left.max1
		tree[node].max2 = if left.max2 > right.max2 { left.max2 } else { right.max2 }
		tree[node].max_count = left.max_count + right.max_count
	} else if left.max1 > right.max1 {
		tree[node].max1 = left.max1
		tree[node].max2 = if left.max2 > right.max1 { left.max2 } else { right.max1 }
		tree[node].max_count = left.max_count
	} else {
		tree[node].max1 = right.max1
		tree[node].max2 = if left.max1 > right.max2 { left.max1 } else { right.max2 }
		tree[node].max_count = right.max_count
	}
	if left.min1 == right.min1 {
		tree[node].min1 = left.min1
		tree[node].min2 = if left.min2 < right.min2 { left.min2 } else { right.min2 }
		tree[node].min_count = left.min_count + right.min_count
	} else if left.min1 < right.min1 {
		tree[node].min1 = left.min1
		tree[node].min2 = if left.min2 < right.min1 { left.min2 } else { right.min1 }
		tree[node].min_count = left.min_count
	} else {
		tree[node].min1 = right.min1
		tree[node].min2 = if left.min1 < right.min2 { left.min1 } else { right.min2 }
		tree[node].min_count = right.min_count
	}
}

fn build(mut tree [tree_size]SegmentNode, values &i64, node int, low int, high int) {
	if high - low == 1 {
		value := unsafe { values[low] }
		tree[node] = SegmentNode{value, value, -inf, value, inf, 0, 1, 1}
		return
	}
	middle := low + (high - low) / 2
	build(mut tree, values, node * 2, low, middle)
	build(mut tree, values, node * 2 + 1, middle, high)
	pull(mut tree, node)
}

fn apply_add(mut tree [tree_size]SegmentNode, node int, length int, delta i64) {
	tree[node].sum += delta * i64(length)
	tree[node].max1 += delta
	tree[node].min1 += delta
	if tree[node].max2 != -inf { tree[node].max2 += delta }
	if tree[node].min2 != inf { tree[node].min2 += delta }
	tree[node].add += delta
}

fn apply_chmin(mut tree [tree_size]SegmentNode, node int, ceiling i64) {
	if tree[node].max1 <= ceiling { return }
	tree[node].sum += (ceiling - tree[node].max1) * i64(tree[node].max_count)
	if tree[node].min1 == tree[node].max1 { tree[node].min1 = ceiling }
	else if tree[node].min2 == tree[node].max1 { tree[node].min2 = ceiling }
	tree[node].max1 = ceiling
}

fn apply_chmax(mut tree [tree_size]SegmentNode, node int, floor i64) {
	if tree[node].min1 >= floor { return }
	tree[node].sum += (floor - tree[node].min1) * i64(tree[node].min_count)
	if tree[node].max1 == tree[node].min1 { tree[node].max1 = floor }
	else if tree[node].max2 == tree[node].min1 { tree[node].max2 = floor }
	tree[node].min1 = floor
}

fn push(mut tree [tree_size]SegmentNode, node int, low int, high int) {
	if high - low == 1 { return }
	middle := low + (high - low) / 2
	delta := tree[node].add
	if delta != 0 {
		apply_add(mut tree, node * 2, middle - low, delta)
		apply_add(mut tree, node * 2 + 1, high - middle, delta)
		tree[node].add = 0
	}
	max1 := tree[node].max1
	if tree[node * 2].max1 > max1 { apply_chmin(mut tree, node * 2, max1) }
	if tree[node * 2 + 1].max1 > max1 { apply_chmin(mut tree, node * 2 + 1, max1) }
	min1 := tree[node].min1
	if tree[node * 2].min1 < min1 { apply_chmax(mut tree, node * 2, min1) }
	if tree[node * 2 + 1].min1 < min1 { apply_chmax(mut tree, node * 2 + 1, min1) }
}

fn range_add(mut tree [tree_size]SegmentNode, node int, low int, high int,
	ql int, qr int, delta i64) {
	if qr <= low || high <= ql || delta == 0 { return }
	if ql <= low && high <= qr {
		apply_add(mut tree, node, high - low, delta)
		return
	}
	push(mut tree, node, low, high)
	middle := low + (high - low) / 2
	range_add(mut tree, node * 2, low, middle, ql, qr, delta)
	range_add(mut tree, node * 2 + 1, middle, high, ql, qr, delta)
	pull(mut tree, node)
}

fn range_chmin(mut tree [tree_size]SegmentNode, node int, low int, high int,
	ql int, qr int, ceiling i64) {
	if qr <= low || high <= ql || tree[node].max1 <= ceiling { return }
	if ql <= low && high <= qr && tree[node].max2 < ceiling {
		apply_chmin(mut tree, node, ceiling)
		return
	}
	push(mut tree, node, low, high)
	middle := low + (high - low) / 2
	range_chmin(mut tree, node * 2, low, middle, ql, qr, ceiling)
	range_chmin(mut tree, node * 2 + 1, middle, high, ql, qr, ceiling)
	pull(mut tree, node)
}

fn range_chmax(mut tree [tree_size]SegmentNode, node int, low int, high int,
	ql int, qr int, floor i64) {
	if qr <= low || high <= ql || tree[node].min1 >= floor { return }
	if ql <= low && high <= qr && tree[node].min2 > floor {
		apply_chmax(mut tree, node, floor)
		return
	}
	push(mut tree, node, low, high)
	middle := low + (high - low) / 2
	range_chmax(mut tree, node * 2, low, middle, ql, qr, floor)
	range_chmax(mut tree, node * 2 + 1, middle, high, ql, qr, floor)
	pull(mut tree, node)
}

fn range_sum(mut tree [tree_size]SegmentNode, node int, low int, high int, ql int, qr int) i64 {
	if qr <= low || high <= ql { return 0 }
	if ql <= low && high <= qr { return tree[node].sum }
	push(mut tree, node, low, high)
	middle := low + (high - low) / 2
	return range_sum(mut tree, node * 2, low, middle, ql, qr) +
		range_sum(mut tree, node * 2 + 1, middle, high, ql, qr)
}

@[export: 'segment_tree_beats']
pub fn segment_tree_beats(values &i64, length usize) i64 {
	unsafe {
		if values == nil || length < 2 || length > usize(max_input_values) { return -1 }
		if values[0] < 1 || values[0] > max_items { return -1 }
		n := int(values[0])
		if length < usize(n + 2) || values[n + 1] < 0 || values[n + 1] > max_operations { return -1 }
		q := int(values[n + 1])
		if length != usize(n + 2 + 4 * q) { return -1 }
		for i := 0; i < n; i++ {
			if values[i + 1] < -value_limit || values[i + 1] > value_limit { return -1 }
		}
		for i := 0; i < q; i++ {
			p := n + 2 + 4 * i
			op, left, right, argument := values[p], values[p + 1], values[p + 2], values[p + 3]
			if op < 0 || op > 3 || left < 0 || left >= right || right > i64(n) { return -1 }
			if op == 3 {
				if argument != 0 { return -1 }
			} else if argument < -value_limit || argument > value_limit { return -1 }
		}

		mut tree := [tree_size]SegmentNode{}
		build(mut tree, &values[1], 1, 0, n)
		mut checksum := i64(0)
		mut ordinal := i64(0)
		for i := 0; i < q; i++ {
			p := n + 2 + 4 * i
			left, right := int(values[p + 1]), int(values[p + 2])
			argument := values[p + 3]
			if values[p] == 0 {
				range_chmin(mut tree, 1, 0, n, left, right, argument)
			} else if values[p] == 1 {
				range_chmax(mut tree, 1, 0, n, left, right, argument)
			} else if values[p] == 2 {
				range_add(mut tree, 1, 0, n, left, right, argument)
			} else {
				ordinal++
				checksum += ordinal * (range_sum(mut tree, 1, 0, n, left, right) + query_offset)
			}
		}
		return checksum
	}
}
