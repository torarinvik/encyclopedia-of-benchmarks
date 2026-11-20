module fenwick_tree_in_block_array_rectangle_count

fn inner_add(mut trees []i64, n int, node int, y i64, delta i64) {
	mut index := int(y) + 1
	for index <= n {
		trees[node * 25 + index] += delta
		index += index & -index
	}
}

fn inner_prefix(trees []i64, node int, y_limit i64) i64 {
	mut index := int(y_limit)
	mut total := i64(0)
	for index > 0 {
		total += trees[node * 25 + index]
		index &= index - 1
	}
	return total
}

fn prefix_count(ys []i64, trees []i64, block_size int, x_limit int, y_limit i64) i64 {
	full_blocks := x_limit / block_size
	mut node := full_blocks
	mut total := i64(0)
	for node > 0 {
		total += inner_prefix(trees, node, y_limit)
		node &= node - 1
	}
	for x := full_blocks * block_size; x < x_limit; x++ {
		if ys[x] < y_limit { total++ }
	}
	return total
}

@[export: 'fenwick_tree_in_block_array_rectangle_count']
pub fn fenwick_tree_in_block_array_rectangle_count(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > 187 { return -1 }
		n_value, q_value := input[0], input[1]
		if n_value < 1 || n_value > 24 || q_value < 1 || q_value > 32 { return -1 }
		n, q := int(n_value), int(q_value)
		operations_at := 2 + n
		if length != usize(operations_at + 5 * q) { return -1 }

		mut ys := [24]i64{}
		for x in 0 .. n {
			ys[x] = input[2 + x]
			if ys[x] < 0 || ys[x] >= n_value { return -1 }
		}
		for j in 0 .. q {
			at := operations_at + 5 * j
			kind := input[at]
			if kind == 0 {
				if input[at + 1] < 0 || input[at + 1] >= n_value || input[at + 2] < 0 || input[at + 2] >= n_value || input[at + 3] != 0 || input[at + 4] != 0 { return -1 }
			} else if kind == 1 {
				if input[at + 1] < 0 || input[at + 1] > input[at + 2] || input[at + 2] > n_value || input[at + 3] < 0 || input[at + 3] > input[at + 4] || input[at + 4] > n_value { return -1 }
			} else { return -1 }
		}

		mut block_size := 1
		for block_size * block_size < n { block_size++ }
		block_count := (n + block_size - 1) / block_size
		mut trees := [150]i64{}
		mut ys_slice := ys[..]
		mut tree_slice := trees[..]
		for x in 0 .. n {
			mut node := x / block_size + 1
			for node <= block_count {
				inner_add(mut tree_slice, n, node, ys[x], 1)
				node += node & -node
			}
		}

		mut checksum := i64(0)
		mut query_ordinal := i64(0)
		for j in 0 .. q {
			at := operations_at + 5 * j
			if input[at] == 0 {
				x := int(input[at + 1])
				new_y := input[at + 2]
				mut node := x / block_size + 1
				for node <= block_count {
					inner_add(mut tree_slice, n, node, ys[x], -1)
					inner_add(mut tree_slice, n, node, new_y, 1)
					node += node & -node
				}
				ys[x] = new_y
			} else {
				x_left, x_right := int(input[at + 1]), int(input[at + 2])
				y_low, y_high := input[at + 3], input[at + 4]
				count := prefix_count(ys_slice, tree_slice, block_size, x_right, y_high) - prefix_count(ys_slice, tree_slice, block_size, x_left, y_high) - prefix_count(ys_slice, tree_slice, block_size, x_right, y_low) + prefix_count(ys_slice, tree_slice, block_size, x_left, y_low)
				query_ordinal++
				checksum += query_ordinal * count
			}
		}
		return checksum
	}
}
