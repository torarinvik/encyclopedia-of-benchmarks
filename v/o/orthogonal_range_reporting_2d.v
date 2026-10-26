module orthogonal_range_reporting_2d

const (
	max_points = 8
	max_queries = 8
	max_input_length = 50
	base = 8
	max_output_words = 73
)

fn lower_x(order &usize, n int, xs &i64, bound i64) int {
	mut low := 0
	mut high := n
	for low < high {
		middle := low + (high - low) / 2
		point := unsafe { order[middle] }
		if unsafe { xs[point] } < bound { low = middle + 1 }
		else { high = middle }
	}
	return low
}

fn upper_x(order &usize, n int, xs &i64, bound i64) int {
	mut low := 0
	mut high := n
	for low < high {
		middle := low + (high - low) / 2
		point := unsafe { order[middle] }
		if unsafe { xs[point] } <= bound { low = middle + 1 }
		else { high = middle }
	}
	return low
}

fn report_node(node int, tree_ids &usize, tree_size &usize, ys &i64,
	y_low i64, y_high i64, mut hits &usize, offset int) int {
	mut low := 0
	mut high := unsafe { tree_size[node] }
	for low < high {
		middle := low + (high - low) / 2
		id := unsafe { tree_ids[node * max_points + middle] }
		if unsafe { ys[id] } < y_low { low = middle + 1 }
		else { high = middle }
	}
	first := low
	high = unsafe { tree_size[node] }
	for low < high {
		middle := low + (high - low) / 2
		id := unsafe { tree_ids[node * max_points + middle] }
		if unsafe { ys[id] } <= y_high { low = middle + 1 }
		else { high = middle }
	}
	for index in first .. low {
		unsafe { hits[offset + index - first] = tree_ids[node * max_points + index] }
	}
	return low - first
}

fn sort_ids(mut ids &usize, count int) {
	for index in 1 .. count {
		item := unsafe { ids[index] }
		mut position := index
		for position > 0 && unsafe { ids[position - 1] } > item {
			unsafe { ids[position] = ids[position - 1] }
			position--
		}
		unsafe { ids[position] = item }
	}
}

fn store_i64_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'orthogonal_range_reporting_2d']
pub fn orthogonal_range_reporting_2d(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if input == nil || length < 2 || length > max_input_length { return -1 }
	n_arg := unsafe { input[0] }
	q_arg := unsafe { input[1] }
	if n_arg < 1 || n_arg > i64(max_points) || q_arg < 1 || q_arg > i64(max_queries) { return -1 }
	n := int(n_arg)
	q := int(q_arg)
	if length != usize(2 + 2 * n + 4 * q) { return -1 }

	mut xs := [8]i64{}
	mut ys := [8]i64{}
	for point in 0 .. n {
		xs[point] = unsafe { input[2 + 2 * point] }
		ys[point] = unsafe { input[3 + 2 * point] }
		if xs[point] < 0 || xs[point] > 15 || ys[point] < 0 || ys[point] > 15 { return -1 }
		for earlier in 0 .. point {
			if xs[earlier] == xs[point] && ys[earlier] == ys[point] { return -1 }
		}
	}
	mut queries := [32]i64{}
	start := 2 + 2 * n
	for query in 0 .. q {
		for item in 0 .. 4 {
			queries[query * 4 + item] = unsafe { input[start + 4 * query + item] }
		}
		if queries[query * 4] < 0 || queries[query * 4] > queries[query * 4 + 1] ||
			queries[query * 4 + 1] > 15 || queries[query * 4 + 2] < 0 ||
			queries[query * 4 + 2] > queries[query * 4 + 3] || queries[query * 4 + 3] > 15 { return -1 }
	}

	mut order := [8]usize{}
	for point in 0 .. n { order[point] = usize(point) }
	for index in 1 .. n {
		item := order[index]
		mut position := index
		for position > 0 {
			previous := order[position - 1]
			before := xs[item] < xs[previous] || (xs[item] == xs[previous] &&
				(ys[item] < ys[previous] || (ys[item] == ys[previous] && item < previous)))
			if !before { break }
			order[position] = previous
			position--
		}
		order[position] = item
	}

	mut tree_ids := [128]usize{}
	mut tree_size := [16]usize{}
	for rank in 0 .. n {
		tree_ids[(base + rank) * max_points] = order[rank]
		tree_size[base + rank] = 1
	}
	for node in 1 .. base {
		parent := base - node
		mut left := 0
		mut right := 0
		left_node := parent * 2
		right_node := parent * 2 + 1
		for left < int(tree_size[left_node]) || right < int(tree_size[right_node]) {
			mut take_left := right >= int(tree_size[right_node])
			if !take_left && left < int(tree_size[left_node]) {
				left_id := tree_ids[left_node * max_points + left]
				right_id := tree_ids[right_node * max_points + right]
				take_left = ys[left_id] < ys[right_id] || (ys[left_id] == ys[right_id] && left_id < right_id)
			}
			mut chosen := usize(0)
			if take_left {
				chosen = tree_ids[left_node * max_points + left]
				left++
			} else {
				chosen = tree_ids[right_node * max_points + right]
				right++
			}
			tree_ids[parent * max_points + int(tree_size[parent])] = chosen
			tree_size[parent]++
		}
	}

	mut words := [73]i64{}
	mut cursor := 0
	words[cursor] = i64(q)
	cursor++
	for query in 0 .. q {
		mut left := lower_x(&order[0], n, &xs[0], queries[query * 4]) + base
		mut right := upper_x(&order[0], n, &xs[0], queries[query * 4 + 1]) + base
		mut hits := [8]usize{}
		mut hit_count := 0
		for left < right {
			if left & 1 != 0 {
				hit_count += report_node(left, &tree_ids[0], &tree_size[0], &ys[0],
					queries[query * 4 + 2], queries[query * 4 + 3], &hits[0], hit_count)
				left++
			}
			if right & 1 != 0 {
				right--
				hit_count += report_node(right, &tree_ids[0], &tree_size[0], &ys[0],
					queries[query * 4 + 2], queries[query * 4 + 3], &hits[0], hit_count)
			}
			left /= 2
			right /= 2
		}
		sort_ids(&hits[0], hit_count)
		words[cursor] = i64(hit_count)
		cursor++
		for index in 0 .. hit_count {
			words[cursor] = i64(hits[index])
			cursor++
		}
	}
	output_bytes := 8 * cursor
	if output == nil || capacity < usize(output_bytes) { return -2 }
	for word in 0 .. cursor { store_i64_le(output, word * 8, words[word]) }
	return i64(output_bytes)
}
