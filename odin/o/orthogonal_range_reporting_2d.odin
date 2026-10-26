package orthogonal_range_reporting_2d

import "core:c"

MAX_POINTS :: 8
MAX_QUERIES :: 8
MAX_INPUT_LENGTH :: 50
BASE :: 8
MAX_OUTPUT_WORDS :: 73

lower_x :: proc(order: [^]usize, n: usize, xs: [^]i64, bound: i64) -> usize {
	low, high := usize(0), n
	for low < high {
		middle := low + (high - low) / 2
		if xs[order[middle]] < bound { low = middle + 1 }
		else { high = middle }
	}
	return low
}

upper_x :: proc(order: [^]usize, n: usize, xs: [^]i64, bound: i64) -> usize {
	low, high := usize(0), n
	for low < high {
		middle := low + (high - low) / 2
		if xs[order[middle]] <= bound { low = middle + 1 }
		else { high = middle }
	}
	return low
}

report_node :: proc(node: usize, tree_ids: [^]usize, tree_size: [^]usize,
	ys: [^]i64, y_low, y_high: i64, hits: [^]usize, offset: usize) -> usize {
	low, high := usize(0), tree_size[node]
	for low < high {
		middle := low + (high - low) / 2
		if ys[tree_ids[node * MAX_POINTS + middle]] < y_low { low = middle + 1 }
		else { high = middle }
	}
	first := low
	high = tree_size[node]
	for low < high {
		middle := low + (high - low) / 2
		if ys[tree_ids[node * MAX_POINTS + middle]] <= y_high { low = middle + 1 }
		else { high = middle }
	}
	for index := first; index < low; index += 1 {
		hits[offset + index - first] = tree_ids[node * MAX_POINTS + index]
	}
	return low - first
}

sort_ids :: proc(ids: [^]usize, count: usize) {
	for index := usize(1); index < count; index += 1 {
		item := ids[index]
		position := index
		for position > 0 && ids[position - 1] > item {
			ids[position] = ids[position - 1]
			position -= 1
		}
		ids[position] = item
	}
}

store_i64_le :: proc(output: [^]u8, offset: usize, value: i64) {
	bits := transmute(u64)(value)
	for byte := usize(0); byte < 8; byte += 1 {
		output[offset + byte] = u8(bits & 255)
		bits >>= 8
	}
}

@(export, link_name="orthogonal_range_reporting_2d")
orthogonal_range_reporting_2d :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > c.size_t(MAX_INPUT_LENGTH) do return -1
	if input[0] < 1 || input[0] > MAX_POINTS || input[1] < 1 || input[1] > MAX_QUERIES do return -1
	n, q := usize(input[0]), usize(input[1])
	if length != c.size_t(2 + 2 * n + 4 * q) do return -1

	xs: [MAX_POINTS]i64
	ys: [MAX_POINTS]i64
	for point := usize(0); point < n; point += 1 {
		xs[point] = input[2 + 2 * point]
		ys[point] = input[3 + 2 * point]
		if xs[point] < 0 || xs[point] > 15 || ys[point] < 0 || ys[point] > 15 do return -1
		for earlier := usize(0); earlier < point; earlier += 1 {
			if xs[earlier] == xs[point] && ys[earlier] == ys[point] do return -1
		}
	}
	queries: [MAX_QUERIES][4]i64
	start := 2 + 2 * n
	for query := usize(0); query < q; query += 1 {
		for item := usize(0); item < 4; item += 1 {
			queries[query][item] = input[start + 4 * query + item]
		}
		if queries[query][0] < 0 || queries[query][0] > queries[query][1] ||
			queries[query][1] > 15 || queries[query][2] < 0 ||
			queries[query][2] > queries[query][3] || queries[query][3] > 15 do return -1
	}

	order: [MAX_POINTS]usize
	for point := usize(0); point < n; point += 1 { order[point] = point }
	for index := usize(1); index < n; index += 1 {
		item := order[index]
		position := index
		for position > 0 {
			previous := order[position - 1]
			before := xs[item] < xs[previous] ||
				(xs[item] == xs[previous] && (ys[item] < ys[previous] ||
					(ys[item] == ys[previous] && item < previous)))
			if !before do break
			order[position] = previous
			position -= 1
		}
		order[position] = item
	}

	tree_ids: [2 * BASE][MAX_POINTS]usize
	tree_size: [2 * BASE]usize
	for node := 0; node < 2 * BASE; node += 1 { tree_size[node] = 0 }
	for rank := usize(0); rank < n; rank += 1 {
		tree_ids[BASE + rank][0] = order[rank]
		tree_size[BASE + rank] = 1
	}
	for node := BASE - 1; node > 0; node -= 1 {
		left, right := usize(0), usize(0)
		left_node, right_node := node * 2, node * 2 + 1
		for left < tree_size[left_node] || right < tree_size[right_node] {
			take_left := right >= tree_size[right_node]
			if !take_left && left < tree_size[left_node] {
				left_id := tree_ids[left_node][left]
				right_id := tree_ids[right_node][right]
				take_left = ys[left_id] < ys[right_id] ||
					(ys[left_id] == ys[right_id] && left_id < right_id)
			}
			chosen: usize
			if take_left {
				chosen = tree_ids[left_node][left]
				left += 1
			} else {
				chosen = tree_ids[right_node][right]
				right += 1
			}
			tree_ids[node][tree_size[node]] = chosen
			tree_size[node] += 1
		}
	}

	words: [MAX_OUTPUT_WORDS]i64
	cursor := usize(0)
	words[cursor] = i64(q)
	cursor += 1
	for query := usize(0); query < q; query += 1 {
		left := lower_x(&order[0], n, &xs[0], queries[query][0]) + BASE
		right := upper_x(&order[0], n, &xs[0], queries[query][1]) + BASE
		hits: [MAX_POINTS]usize
		hit_count := usize(0)
		for left < right {
			if (left & 1) != 0 {
				hit_count += report_node(left, &tree_ids[0][0], &tree_size[0], &ys[0],
					queries[query][2], queries[query][3], &hits[0], hit_count)
				left += 1
			}
			if (right & 1) != 0 {
				right -= 1
				hit_count += report_node(right, &tree_ids[0][0], &tree_size[0], &ys[0],
					queries[query][2], queries[query][3], &hits[0], hit_count)
			}
			left /= 2
			right /= 2
		}
		sort_ids(&hits[0], hit_count)
		words[cursor] = i64(hit_count)
		cursor += 1
		for index := usize(0); index < hit_count; index += 1 {
			words[cursor] = i64(hits[index])
			cursor += 1
		}
	}
	output_bytes := c.size_t(8 * cursor)
	if output == nil || capacity < output_bytes do return -2
	for word := usize(0); word < cursor; word += 1 {
		store_i64_le(output, word * 8, words[word])
	}
	return i64(output_bytes)
}
