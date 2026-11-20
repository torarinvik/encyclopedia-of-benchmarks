package fenwick_tree_in_block_array_rectangle_count

import "core:c"

inner_add :: proc(trees: [^]i64, n, node: usize, y, delta: i64) {
	index := usize(y) + 1
	for index <= n {
		trees[node * 25 + index] += delta
		index += index & (~index + 1)
	}
}

inner_prefix :: proc(trees: [^]i64, node: usize, y_limit: i64) -> i64 {
	index := usize(y_limit)
	total := i64(0)
	for index > 0 {
		total += trees[node * 25 + index]
		index -= index & (~index + 1)
	}
	return total
}

prefix_count :: proc(ys: [^]i64, trees: [^]i64, block_size, x_limit: usize, y_limit: i64) -> i64 {
	full_blocks := x_limit / block_size
	node := full_blocks
	total := i64(0)
	for node > 0 {
		total += inner_prefix(trees, node, y_limit)
		node -= node & (~node + 1)
	}
	for x := full_blocks * block_size; x < x_limit; x += 1 {
		if ys[x] < y_limit do total += 1
	}
	return total
}

@(export)
fenwick_tree_in_block_array_rectangle_count :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > 187 do return -1
	n_value, q_value := input[0], input[1]
	if n_value < 1 || n_value > 24 || q_value < 1 || q_value > 32 do return -1
	n, q := usize(n_value), usize(q_value)
	operations_at := 2 + n
	if length != operations_at + 5 * q do return -1

	var ys: [24]i64
	for x: usize = 0; x < n; x += 1 {
		ys[x] = input[2 + x]
		if ys[x] < 0 || ys[x] >= n_value do return -1
	}
	for j: usize = 0; j < q; j += 1 {
		at := operations_at + 5 * j
		kind := input[at]
		if kind == 0 {
			if input[at+1] < 0 || input[at+1] >= n_value || input[at+2] < 0 || input[at+2] >= n_value || input[at+3] != 0 || input[at+4] != 0 do return -1
		} else if kind == 1 {
			if input[at+1] < 0 || input[at+1] > input[at+2] || input[at+2] > n_value || input[at+3] < 0 || input[at+3] > input[at+4] || input[at+4] > n_value do return -1
		} else do return -1
	}

	block_size := usize(1)
	for block_size * block_size < n { block_size += 1 }
	block_count := (n + block_size - 1) / block_size
	var trees: [150]i64
	for x: usize = 0; x < n; x += 1 {
		node := x / block_size + 1
		for node <= block_count {
			inner_add(&trees[0], n, node, ys[x], 1)
			node += node & (~node + 1)
		}
	}

	checksum := i64(0)
	query_ordinal := i64(0)
	for j: usize = 0; j < q; j += 1 {
		at := operations_at + 5 * j
		if input[at] == 0 {
			x := usize(input[at+1])
			new_y := input[at+2]
			node := x / block_size + 1
			for node <= block_count {
				inner_add(&trees[0], n, node, ys[x], -1)
				inner_add(&trees[0], n, node, new_y, 1)
				node += node & (~node + 1)
			}
			ys[x] = new_y
		} else {
			x_left, x_right := usize(input[at+1]), usize(input[at+2])
			y_low, y_high := input[at+3], input[at+4]
			count := prefix_count(&ys[0], &trees[0], block_size, x_right, y_high) - prefix_count(&ys[0], &trees[0], block_size, x_left, y_high) - prefix_count(&ys[0], &trees[0], block_size, x_right, y_low) + prefix_count(&ys[0], &trees[0], block_size, x_left, y_low)
			query_ordinal += 1
			checksum += query_ordinal * count
		}
	}
	return checksum
}
