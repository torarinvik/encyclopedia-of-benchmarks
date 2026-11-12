module jump_on_tree

const max_n = 64
const max_q = 64
const max_levels = 7
const max_input_values = 2 + 2 * (max_n - 1) + 3 * max_q

fn find_root(mut parent []int, item int) int {
	mut node := item
	for parent[node] != node {
		parent[node] = parent[parent[node]]
		node = parent[node]
	}
	return node
}

fn lift(ancestors []int, vertex int, distance int) int {
	mut node := vertex
	for bit in 0 .. max_levels {
		if ((distance >> bit) & 1) != 0 {
			node = ancestors[node * max_levels + bit]
		}
	}
	return node
}

fn lowest_common_ancestor(ancestors []int, depth []int, left_value int, right_value int) int {
	mut left := left_value
	mut right := right_value
	if depth[left] < depth[right] {
		left, right = right, left
	}
	left = lift(ancestors, left, depth[left] - depth[right])
	if left == right {
		return left
	}
	for level := max_levels - 1; level >= 0; level-- {
		if ancestors[left * max_levels + level] != ancestors[right * max_levels + level] {
			left = ancestors[left * max_levels + level]
			right = ancestors[right * max_levels + level]
		}
	}
	return ancestors[left * max_levels]
}

fn store_i64_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	unsafe {
		for byte in 0 .. 8 {
			output[offset + byte] = u8(bits & 255)
			bits >>= 8
		}
	}
}

@[export: 'jump_on_tree']
pub fn jump_on_tree(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > max_input_values {
		return -1
	}
	n_value := unsafe { input[0] }
	q_value := unsafe { input[1] }
	if n_value < 2 || n_value > max_n || q_value < 1 || q_value > max_q {
		return -1
	}
	n := int(n_value)
	q := int(q_value)
	query_start := 2 + 2 * (n - 1)
	if length != usize(query_start + 3 * q) {
		return -1
	}

	mut adjacent := []bool{len: max_n * max_n}
	mut dsu_parent := []int{len: max_n}
	mut dsu_size := []int{len: max_n, init: 1}
	for vertex in 0 .. n {
		dsu_parent[vertex] = vertex
	}
	for edge in 0 .. (n - 1) {
		offset := 2 + 2 * edge
		left_value := unsafe { input[offset] }
		right_value := unsafe { input[offset + 1] }
		if left_value < 0 || left_value >= n_value || right_value < 0 ||
			right_value >= n_value || left_value == right_value {
			return -1
		}
		left := int(left_value)
		right := int(right_value)
		mut root_left := find_root(mut dsu_parent, left)
		mut root_right := find_root(mut dsu_parent, right)
		if root_left == root_right {
			return -1
		}
		if dsu_size[root_left] < dsu_size[root_right] {
			root_left, root_right = root_right, root_left
		}
		dsu_parent[root_right] = root_left
		dsu_size[root_left] += dsu_size[root_right]
		adjacent[left * max_n + right] = true
		adjacent[right * max_n + left] = true
	}

	mut ancestors := []int{len: max_n * max_levels}
	mut depth := []int{len: max_n}
	mut visited := []bool{len: max_n}
	mut stack := []int{len: max_n}
	mut top := 1
	stack[0] = 0
	visited[0] = true
	for top > 0 {
		top--
		vertex := stack[top]
		for neighbor in 0 .. n {
			cell := vertex * max_n + neighbor
			if !adjacent[cell] || visited[neighbor] {
				continue
			}
			visited[neighbor] = true
			ancestors[neighbor * max_levels] = vertex
			depth[neighbor] = depth[vertex] + 1
			stack[top] = neighbor
			top++
		}
	}
	for level in 1 .. max_levels {
		for vertex in 0 .. n {
			ancestor := ancestors[vertex * max_levels + level - 1]
			ancestors[vertex * max_levels + level] = ancestors[ancestor * max_levels + level - 1]
		}
	}

	mut answers := []i64{len: max_q}
	for query in 0 .. q {
		offset := query_start + 3 * query
		start_value := unsafe { input[offset] }
		target_value := unsafe { input[offset + 1] }
		index_value := unsafe { input[offset + 2] }
		if start_value < 0 || start_value >= n_value || target_value < 0 ||
			target_value >= n_value || index_value < 0 || index_value >= n_value {
			return -1
		}
		start := int(start_value)
		target := int(target_value)
		index := int(index_value)
		common := lowest_common_ancestor(ancestors, depth, start, target)
		upward := depth[start] - depth[common]
		path_length := upward + depth[target] - depth[common]
		if index > path_length {
			answers[query] = -1
		} else if index <= upward {
			answers[query] = i64(lift(ancestors, start, index))
		} else {
			answers[query] = i64(lift(ancestors, target, path_length - index))
		}
	}

	required := 8 * q
	if unsafe { output == nil } || capacity < usize(required) {
		return -2
	}
	for query in 0 .. q {
		store_i64_le(mut output, 8 * query, answers[query])
	}
	return i64(required)
}
