module common_interval_decomposition_tree

const max_n = 48
const max_nodes = 2 * max_n - 1
const grid = max_n * max_n

fn store_i64_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	unsafe {
		for byte in 0 .. 8 {
			output[offset + byte] = u8(bits & 255)
			bits >>= 8
		}
	}
}

fn intervals_overlap(left_a, right_a, left_b, right_b int) bool {
	return (left_a < left_b && left_b <= right_a && right_a < right_b) ||
		(left_b < left_a && left_a <= right_b && right_b < right_a)
}

@[export: 'common_interval_decomposition_tree']
pub fn common_interval_decomposition_tree(input &i64, length usize,
	mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > usize(1 + max_n) { return -1 }
	n_value := unsafe { input[0] }
	if n_value < 1 || n_value > max_n { return -1 }
	n := int(n_value)
	if length != usize(n + 1) { return -1 }

	mut seen := []bool{len: max_n}
	for i in 0 .. n {
		value := unsafe { input[i + 1] }
		if value < 0 || value >= i64(n) { return -1 }
		if seen[int(value)] { return -1 }
		seen[int(value)] = true
	}

	mut connected := []bool{len: grid}
	mut strong := []bool{len: grid}
	for left in 0 .. n {
		mut minimum := i64(n)
		mut maximum := i64(-1)
		for right in left .. n {
			value := unsafe { input[right + 1] }
			if value < minimum { minimum = value }
			if value > maximum { maximum = value }
			slot := left * max_n + right
			if maximum - minimum == i64(right - left) {
				connected[slot] = true
				strong[slot] = true
			}
		}
	}

	for left_a in 0 .. n {
		for right_a in left_a .. n {
			slot_a := left_a * max_n + right_a
			if !connected[slot_a] { continue }
			for left_b in 0 .. n {
				for right_b in left_b .. n {
					slot_b := left_b * max_n + right_b
					if slot_b <= slot_a || !connected[slot_b] { continue }
					if intervals_overlap(left_a, right_a, left_b, right_b) {
						strong[slot_a] = false
						strong[slot_b] = false
					}
				}
			}
		}
	}

	mut node_left := []int{len: max_nodes}
	mut node_right := []int{len: max_nodes}
	mut parent := []int{len: max_nodes, init: -1}
	mut node_type := []int{len: max_nodes}
	mut node_count := 0
	mut span := n
	for span > 0 {
		for left := 0; left + span <= n; left++ {
			right := left + span - 1
			if !strong[left * max_n + right] { continue }
			node_left[node_count] = left
			node_right[node_count] = right
			node_count++
		}
		span--
	}
	if node_count == 0 || node_count > max_nodes { return -1 }

	for node in 0 .. node_count {
		span_here := node_right[node] - node_left[node] + 1
		mut best_span := n + 1
		for candidate in 0 .. node_count {
			candidate_span := node_right[candidate] - node_left[candidate] + 1
			if candidate_span > span_here && candidate_span < best_span &&
				node_left[candidate] <= node_left[node] && node_right[node] <= node_right[candidate] {
				parent[node] = candidate
				best_span = candidate_span
			}
		}
	}

	for node in 0 .. node_count {
		mut children := []int{len: max_n}
		mut child_count := 0
		for child in 0 .. node_count {
			if parent[child] != node { continue }
			mut at := child_count
			for at > 0 && node_left[children[at - 1]] > node_left[child] {
				children[at] = children[at - 1]
				at--
			}
			children[at] = child
			child_count++
		}

		for first in 0 .. child_count {
			for last := first; last < child_count; last++ {
				left := node_left[children[first]]
				right := node_right[children[last]]
				mut minimum := i64(n)
				mut maximum := i64(-1)
				for position in left .. right + 1 {
					value := unsafe { input[position + 1] }
					if value < minimum { minimum = value }
					if value > maximum { maximum = value }
				}
				if maximum - minimum != i64(right - left) {
					node_type[node] = 1
					break
				}
			}
			if node_type[node] != 0 { break }
		}
	}

	output_bytes := (1 + 4 * node_count) * 8
	if unsafe { output == nil } || capacity < usize(output_bytes) { return -2 }
	store_i64_le(mut output, 0, i64(node_count))
	for node in 0 .. node_count {
		offset := 8 + 32 * node
		store_i64_le(mut output, offset, i64(parent[node]))
		store_i64_le(mut output, offset + 8, i64(node_left[node]))
		store_i64_le(mut output, offset + 16, i64(node_right[node]))
		store_i64_le(mut output, offset + 24, i64(node_type[node]))
	}
	return i64(output_bytes)
}
