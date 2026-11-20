module tree_center

const max_n = 64
const max_input_length = 1 + 2 * (max_n - 1)
const matrix_cells = max_n * max_n

fn find_root(mut parent []int, item int) int {
	mut node := item
	for parent[node] != node {
		parent[node] = parent[parent[node]]
		node = parent[node]
	}
	return node
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

@[export: 'tree_center']
pub fn tree_center(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 1 || length > max_input_length { return -1 }
	n_value := unsafe { input[0] }
	if n_value < 1 || n_value > max_n { return -1 }
	n := int(n_value)
	if length != usize(1 + 2 * (n - 1)) { return -1 }

	mut adjacency := []int{len: matrix_cells}
	mut adjacency_count := []int{len: max_n}
	mut degree := []int{len: max_n}
	mut parent := []int{len: max_n}
	mut component_size := []int{len: max_n}
	for vertex in 0 .. n {
		parent[vertex] = vertex
		component_size[vertex] = 1
	}
	for edge in 0 .. (n - 1) {
		offset := 1 + 2 * edge
		left_value := unsafe { input[offset] }
		right_value := unsafe { input[offset + 1] }
		if left_value < 0 || left_value >= n_value || right_value < 0 ||
			right_value >= n_value || left_value == right_value { return -1 }
		left := int(left_value)
		right := int(right_value)
		mut root_left := find_root(mut parent, left)
		mut root_right := find_root(mut parent, right)
		if root_left == root_right { return -1 }
		if component_size[root_left] < component_size[root_right] {
			root_left, root_right = root_right, root_left
		}
		parent[root_right] = root_left
		component_size[root_left] += component_size[root_right]
		adjacency[left * max_n + adjacency_count[left]] = right
		adjacency_count[left]++
		adjacency[right * max_n + adjacency_count[right]] = left
		adjacency_count[right]++
		degree[left]++
		degree[right]++
	}
	if n > 1 && component_size[find_root(mut parent, 0)] != n { return -1 }

	mut active := []bool{len: max_n}
	mut leaves := []int{len: max_n}
	mut leaf_count := 0
	for vertex in 0 .. n {
		active[vertex] = true
		if degree[vertex] <= 1 {
			leaves[leaf_count] = vertex
			leaf_count++
		}
	}
	mut remaining := n
	for remaining > 2 {
		for index in 0 .. leaf_count { active[leaves[index]] = false }
		remaining -= leaf_count
		for index in 0 .. leaf_count {
			leaf := leaves[index]
			for edge in 0 .. adjacency_count[leaf] {
				neighbor := adjacency[leaf * max_n + edge]
				if active[neighbor] { degree[neighbor]-- }
			}
		}
		if remaining <= 2 { break }
		leaf_count = 0
		for vertex in 0 .. n {
			if active[vertex] && degree[vertex] == 1 {
				leaves[leaf_count] = vertex
				leaf_count++
			}
		}
	}

	mut centers := []i64{len: 2}
	mut center_count := 0
	for vertex in 0 .. n {
		if active[vertex] {
			centers[center_count] = i64(vertex)
			center_count++
		}
	}
	required := 8 * center_count
	if unsafe { output == nil } || capacity < usize(required) { return -2 }
	for index in 0 .. center_count {
		store_i64_le(mut output, 8 * index, centers[index])
	}
	return i64(required)
}
