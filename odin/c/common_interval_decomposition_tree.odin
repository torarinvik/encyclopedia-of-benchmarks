package common_interval_decomposition_tree

import "core:c"

MAX_N :: 48
MAX_NODES :: 2 * MAX_N - 1
GRID :: MAX_N * MAX_N

store_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8(bits & 255)
		bits >>= 8
	}
}

intervals_overlap :: proc "contextless" (left_a, right_a, left_b, right_b: int) -> bool {
	return (left_a < left_b && left_b <= right_a && right_a < right_b) ||
		(left_b < left_a && left_a <= right_b && right_b < right_a)
}

@(export)
common_interval_decomposition_tree :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > 1 + MAX_N do return -1
	n_value := input[0]
	if n_value < 1 || n_value > i64(MAX_N) do return -1
	n := int(n_value)
	if length != c.size_t(n + 1) do return -1

	seen: [MAX_N]bool
	for i := 0; i < n; i += 1 {
		value := input[i + 1]
		if value < 0 || value >= i64(n) || seen[int(value)] do return -1
		seen[int(value)] = true
	}

	connected: [GRID]bool
	strong: [GRID]bool
	for left := 0; left < n; left += 1 {
		minimum := i64(n)
		maximum := i64(-1)
		for right := left; right < n; right += 1 {
			value := input[right + 1]
			if value < minimum do minimum = value
			if value > maximum do maximum = value
			slot := left * MAX_N + right
			if maximum - minimum == i64(right - left) {
				connected[slot] = true
				strong[slot] = true
			}
		}
	}

	for left_a := 0; left_a < n; left_a += 1 {
		for right_a := left_a; right_a < n; right_a += 1 {
			slot_a := left_a * MAX_N + right_a
			if !connected[slot_a] do continue
			for left_b := 0; left_b < n; left_b += 1 {
				for right_b := left_b; right_b < n; right_b += 1 {
					slot_b := left_b * MAX_N + right_b
					if slot_b <= slot_a || !connected[slot_b] do continue
					if intervals_overlap(left_a, right_a, left_b, right_b) {
						strong[slot_a] = false
						strong[slot_b] = false
					}
				}
			}
		}
	}

	node_left: [MAX_NODES]int
	node_right: [MAX_NODES]int
	parent: [MAX_NODES]int
	node_type: [MAX_NODES]int
	node_count := 0
	for span := n; span > 0; span -= 1 {
		for left := 0; left + span <= n; left += 1 {
			right := left + span - 1
			if !strong[left * MAX_N + right] do continue
			node_left[node_count] = left
			node_right[node_count] = right
			node_count += 1
		}
	}
	if node_count == 0 || node_count > MAX_NODES do return -1

	for node := 0; node < node_count; node += 1 {
		span := node_right[node] - node_left[node] + 1
		best_span := n + 1
		parent[node] = -1
		for candidate := 0; candidate < node_count; candidate += 1 {
			candidate_span := node_right[candidate] - node_left[candidate] + 1
			if candidate_span > span && candidate_span < best_span &&
				node_left[candidate] <= node_left[node] && node_right[node] <= node_right[candidate] {
				parent[node] = candidate
				best_span = candidate_span
			}
		}
	}

	for node := 0; node < node_count; node += 1 {
		children: [MAX_N]int
		child_count := 0
		for child := 0; child < node_count; child += 1 {
			if parent[child] != node do continue
			at := child_count
			for at > 0 && node_left[children[at - 1]] > node_left[child] {
				children[at] = children[at - 1]
				at -= 1
			}
			children[at] = child
			child_count += 1
		}

		for first := 0; first < child_count; first += 1 {
			for last := first; last < child_count; last += 1 {
				left := node_left[children[first]]
				right := node_right[children[last]]
				minimum := i64(n)
				maximum := i64(-1)
				for position := left; position <= right; position += 1 {
					value := input[position + 1]
					if value < minimum do minimum = value
					if value > maximum do maximum = value
				}
				if maximum - minimum != i64(right - left) {
					node_type[node] = 1
					break
				}
			}
			if node_type[node] != 0 do break
		}
	}

	output_bytes := (1 + 4 * node_count) * 8
	if output == nil || capacity < c.size_t(output_bytes) do return -2
	store_i64_le(output, 0, i64(node_count))
	for node := 0; node < node_count; node += 1 {
		offset := 8 + 32 * node
		store_i64_le(output, offset, i64(parent[node]))
		store_i64_le(output, offset + 8, i64(node_left[node]))
		store_i64_le(output, offset + 16, i64(node_right[node]))
		store_i64_le(output, offset + 24, i64(node_type[node]))
	}
	return i64(output_bytes)
}
