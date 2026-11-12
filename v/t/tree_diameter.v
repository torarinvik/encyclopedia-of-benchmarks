module tree_diameter

const max_n = 64
const max_input_values = 1 + 3 * (max_n - 1)
const max_output_values = 2 + max_n
const matrix_cells = max_n * max_n
const max_edge_weight = i64(1_000_000_000)

fn find_root(mut parent []int, item int) int {
	mut node := item
	for parent[node] != node {
		parent[node] = parent[parent[node]]
		node = parent[node]
	}
	return node
}

fn traverse(n int, start int, adjacent []bool, weights []i64,
	mut distance []i64, mut path_parent []i64) {
	mut stack := []int{len: max_n}
	for vertex in 0 .. n {
		distance[vertex] = -1
		path_parent[vertex] = -1
	}
	mut top := 1
	stack[0] = start
	distance[start] = 0
	for top > 0 {
		top--
		current := stack[top]
		for neighbor in 0 .. n {
			cell := current * max_n + neighbor
			if adjacent[cell] && distance[neighbor] < 0 {
				distance[neighbor] = distance[current] + weights[cell]
				path_parent[neighbor] = i64(current)
				stack[top] = neighbor
				top++
			}
		}
	}
}

fn farthest(n int, distance []i64) int {
	mut best := 0
	for vertex in 1 .. n {
		if distance[vertex] > distance[best] ||
			(distance[vertex] == distance[best] && vertex < best) {
			best = vertex
		}
	}
	return best
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

@[export: 'tree_diameter']
pub fn tree_diameter(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 1 || length > max_input_values {
		return -1
	}
	n_value := unsafe { input[0] }
	if n_value < 1 || n_value > max_n {
		return -1
	}
	n := int(n_value)
	if length != usize(1 + 3 * (n - 1)) {
		return -1
	}

	mut adjacent := []bool{len: matrix_cells}
	mut weights := []i64{len: matrix_cells}
	mut dsu_parent := []int{len: max_n}
	mut dsu_size := []int{len: max_n, init: 1}
	for vertex in 0 .. n {
		dsu_parent[vertex] = vertex
	}
	for edge in 0 .. (n - 1) {
		offset := 1 + 3 * edge
		left_value := unsafe { input[offset] }
		right_value := unsafe { input[offset + 1] }
		edge_weight := unsafe { input[offset + 2] }
		if left_value < 0 || left_value >= n_value || right_value < 0 ||
			right_value >= n_value || left_value == right_value ||
			edge_weight < 1 || edge_weight > max_edge_weight {
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
		weights[left * max_n + right] = edge_weight
		weights[right * max_n + left] = edge_weight
	}

	mut distance := []i64{len: max_n}
	mut path_parent := []i64{len: max_n}
	traverse(n, 0, adjacent, weights, mut distance, mut path_parent)
	first_endpoint := farthest(n, distance)
	traverse(n, first_endpoint, adjacent, weights, mut distance, mut path_parent)
	second_endpoint := farthest(n, distance)
	mut reverse_path := []int{len: max_n}
	mut path_length := 0
	mut current := i64(second_endpoint)
	for current >= 0 {
		reverse_path[path_length] = int(current)
		path_length++
		if int(current) == first_endpoint {
			break
		}
		current = path_parent[int(current)]
	}

	mut staged := []i64{len: max_output_values}
	mut used := 0
	staged[used] = distance[second_endpoint]
	used++
	staged[used] = i64(path_length)
	used++
	for position in 0 .. path_length {
		staged[used] = i64(reverse_path[path_length - 1 - position])
		used++
	}
	required := 8 * used
	if unsafe { output == nil } || capacity < usize(required) {
		return -2
	}
	for index in 0 .. used {
		store_i64_le(mut output, 8 * index, staged[index])
	}
	return i64(required)
}
