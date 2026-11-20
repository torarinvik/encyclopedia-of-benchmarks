module tree_center_rerooting_dp

import "core:c"

const max_n = 64
const max_input_length = 1 + 2 * (max_n - 1)

fn store_i64_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	unsafe {
		for byte in 0 .. 8 {
			output[offset + byte] = u8(bits & 255)
			bits >>= 8
		}
	}
}

@[export: 'tree_center_rerooting_dp']
pub fn tree_center_rerooting_dp(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 1 || length > max_input_length { return -1 }
	n_value := unsafe { input[0] }
	if n_value < 1 || n_value > max_n { return -1 }
	n := int(n_value)
	if length != usize(1 + 2 * (n - 1)) { return -1 }

	mut adjacency := []int{len: max_n * max_n}
	mut degree := []int{len: max_n}
	for edge in 0 .. (n - 1) {
		offset := 1 + 2 * edge
		left_value := unsafe { input[offset] }
		right_value := unsafe { input[offset + 1] }
		if left_value < 0 || left_value >= n_value || right_value < 0 ||
			right_value >= n_value || left_value == right_value { return -1 }
		left := int(left_value)
		right := int(right_value)
		adjacency[left * max_n + degree[left]] = right
		degree[left]++
		adjacency[right * max_n + degree[right]] = left
		degree[right]++
	}

	mut parent := []int{len: max_n, init: max_n}
	mut order := []int{len: max_n}
	parent[0] = max_n + 1
	order[0] = 0
	mut order_count := 1
	mut position := 0
	for position < order_count {
		vertex := order[position]
		for edge in 0 .. degree[vertex] {
			child := adjacency[vertex * max_n + edge]
			if child == parent[vertex] { continue }
			if parent[child] != max_n { return -1 }
			parent[child] = vertex
			order[order_count] = child
			order_count++
		}
		position++
	}
	if order_count != n { return -1 }

	mut down := []int{len: max_n}
	mut best := []int{len: max_n}
	mut second := []int{len: max_n}
	mut best_child := []int{len: max_n, init: max_n}
	position = n
	for position > 0 {
		position--
		vertex := order[position]
		for edge in 0 .. degree[vertex] {
			child := adjacency[vertex * max_n + edge]
			if parent[child] != vertex { continue }
			branch := down[child] + 1
			if branch > best[vertex] {
				second[vertex] = best[vertex]
				best[vertex] = branch
				best_child[vertex] = child
			} else if branch > second[vertex] {
				second[vertex] = branch
			}
		}
		down[vertex] = best[vertex]
	}

	mut outside := []int{len: max_n, init: -1}
	for i in 0 .. n {
		vertex := order[i]
		for edge in 0 .. degree[vertex] {
			child := adjacency[vertex * max_n + edge]
			if parent[child] != vertex { continue }
			sibling := best[vertex]
			if best_child[vertex] == child { sibling = second[vertex] }
			base := outside[vertex]
			if sibling > base { base = sibling }
			outside[child] = base + 1
		}
	}

	mut radius := max_n
	for vertex in 0 .. n {
		eccentricity := down[vertex]
		if outside[vertex] > eccentricity { eccentricity = outside[vertex] }
		if eccentricity < radius { radius = eccentricity }
	}
	mut centers := []i64{len: 2}
	mut center_count := 0
	for vertex in 0 .. n {
		eccentricity := down[vertex]
		if outside[vertex] > eccentricity { eccentricity = outside[vertex] }
		if eccentricity == radius {
			centers[center_count] = i64(vertex)
			center_count++
		}
	}
	required := 8 * center_count
	if unsafe { output == nil } || capacity < usize(required) { return -2 }
	for i in 0 .. center_count { store_i64_le(mut output, 8 * i, centers[i]) }
	return i64(required)
}
