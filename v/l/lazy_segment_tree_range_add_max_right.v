const max_valid_length = 66
const max_parseable_length = 67
const tree_length = 64

fn lazy_apply(mut tree [tree_length]i64, mut pending [tree_length]i64, node int, segment_length int, delta i64) {
	tree[node] += delta * i64(segment_length)
	pending[node] += delta
}

fn lazy_push(mut tree [tree_length]i64, mut pending [tree_length]i64, node int, segment_length int) {
	if segment_length > 1 && pending[node] != 0 {
		half := segment_length / 2
		delta := pending[node]
		lazy_apply(mut tree, mut pending, 2 * node, half, delta)
		lazy_apply(mut tree, mut pending, 2 * node + 1, half, delta)
		pending[node] = 0
	}
}

fn lazy_add(mut tree [tree_length]i64, mut pending [tree_length]i64, node int,
	low int, high int, query_low int, query_high int, delta i64) {
	if query_low >= query_high { return }
	if query_high <= low || high <= query_low { return }
	if query_low <= low && high <= query_high {
		lazy_apply(mut tree, mut pending, node, high - low, delta)
		return
	}
	lazy_push(mut tree, mut pending, node, high - low)
	middle := (low + high) / 2
	if query_low < middle { lazy_add(mut tree, mut pending, 2 * node, low, middle, query_low, query_high, delta) }
	if query_high > middle { lazy_add(mut tree, mut pending, 2 * node + 1, middle, high, query_low, query_high, delta) }
	tree[node] = tree[2 * node] + tree[2 * node + 1]
}

fn lazy_max_right(mut tree [tree_length]i64, mut pending [tree_length]i64,
	node int, low int, high int, n int, left int, limit i64, mut accumulated i64) int {
	if high <= left { return high }
	if low >= n { return n }
	if left <= low && high <= n && accumulated + tree[node] <= limit {
		accumulated += tree[node]
		return high
	}
	if high - low == 1 { return low }
	lazy_push(mut tree, mut pending, node, high - low)
	middle := (low + high) / 2
	first := lazy_max_right(mut tree, mut pending, 2 * node, low, middle, n, left, limit, mut accumulated)
	if first < middle && first >= left { return first }
	return lazy_max_right(mut tree, mut pending, 2 * node + 1, middle, high, n, left, limit, mut accumulated)
}

@[export: 'lazy_segment_tree_range_add_max_right']
pub fn lazy_segment_tree_range_add_max_right(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > max_parseable_length { return -1 }
		if input[0] < 1 || input[0] > 16 || input[1] < 0 || input[1] > 12 { return -1 }
		n := int(input[0])
		operations := int(input[1])
		if length != usize(2 + n + 4 * operations) || length > max_valid_length { return -1 }
		for i in 0 .. n {
			if input[2 + i] < 0 || input[2 + i] > 31 { return -1 }
		}
		for operation in 0 .. operations {
			p := 2 + n + 4 * operation
			opcode, left, right, extra := input[p], input[p + 1], input[p + 2], input[p + 3]
			if opcode == 0 {
				if left < 0 || left > i64(n) || right < left || right > i64(n) || extra < 0 || extra > 31 { return -1 }
			} else if opcode == 1 {
				if left < 0 || left > i64(n) || right < 0 || right > 8192 || extra != 0 { return -1 }
			} else { return -1 }
		}

		mut base := 1
		for base < n { base *= 2 }
		mut tree := [tree_length]i64{}
		mut pending := [tree_length]i64{}
		for i in 0 .. n { tree[base + i] = input[2 + i] }
		mut node := base
		for node > 1 {
			node -= 1
			tree[node] = tree[2 * node] + tree[2 * node + 1]
		}

		mut query_index := 0
		mut result := i64(0)
		for operation in 0 .. operations {
			p := 2 + n + 4 * operation
			left, right := int(input[p + 1]), int(input[p + 2])
			if input[p] == 0 {
				lazy_add(mut tree, mut pending, 1, 0, base, left, right, input[p + 3])
			} else {
				mut accumulated := i64(0)
				boundary := lazy_max_right(mut tree, mut pending, 1, 0, base, n, left, i64(right), mut accumulated)
				result |= i64(boundary) << u32(5 * query_index)
				query_index += 1
			}
		}
		return result
	}
}
