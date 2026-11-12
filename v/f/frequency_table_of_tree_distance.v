module frequency_table_of_tree_distance

const max_n = 64
const max_input_values = 1 + 2 * (max_n - 1)

struct WalkItem {
	vertex int
	parent int
	depth int
}

fn find_root(mut parent []int, item int) int {
	mut node := item
	for parent[node] != node {
		parent[node] = parent[parent[node]]
		node = parent[node]
	}
	return node
}

fn solve_component(n int, adjacent []bool, mut removed []bool, mut answer []i64, start int) {
	mut order := []int{len: max_n}
	mut parent := []int{len: max_n}
	mut subtree := []int{len: max_n}
	mut stack := []int{len: max_n}
	mut order_count := 0
	mut top := 1
	stack[0] = start
	parent[start] = start
	subtree[start] = 1
	order[order_count] = start
	order_count++
	for top > 0 {
		top--
		vertex := stack[top]
		for neighbor in 0 .. n {
			if !adjacent[vertex * max_n + neighbor] || removed[neighbor] || neighbor == parent[vertex] {
				continue
			}
			parent[neighbor] = vertex
			subtree[neighbor] = 1
			order[order_count] = neighbor
			order_count++
			stack[top] = neighbor
			top++
		}
	}
	mut position := order_count
	for position > 1 {
		position--
		vertex := order[position]
		subtree[parent[vertex]] += subtree[vertex]
	}

	mut centroid := max_n
	for index in 0 .. order_count {
		vertex := order[index]
		mut largest_part := order_count - subtree[vertex]
		for neighbor in 0 .. n {
			if adjacent[vertex * max_n + neighbor] && !removed[neighbor] && parent[neighbor] == vertex &&
				subtree[neighbor] > largest_part {
				largest_part = subtree[neighbor]
			}
		}
		if 2 * largest_part <= order_count && (centroid == max_n || vertex < centroid) {
			centroid = vertex
		}
	}

	mut frequency := []i64{len: max_n}
	mut frequency_max := 0
	frequency[0] = 1
	removed[centroid] = true
	for child in 0 .. n {
		if !adjacent[centroid * max_n + child] || removed[child] {
			continue
		}
		mut local_frequency := []int{len: max_n}
		mut walk := []WalkItem{len: max_n}
		mut local_max := 0
		mut walk_top := 1
		walk[0] = WalkItem{vertex: child, parent: centroid, depth: 1}
		for walk_top > 0 {
			walk_top--
			item := walk[walk_top]
			local_frequency[item.depth]++
			if item.depth > local_max {
				local_max = item.depth
			}
			for neighbor in 0 .. n {
				if adjacent[item.vertex * max_n + neighbor] && !removed[neighbor] && neighbor != item.parent {
					walk[walk_top] = WalkItem{vertex: neighbor, parent: item.vertex, depth: item.depth + 1}
					walk_top++
				}
			}
		}
		for depth in 1 .. (local_max + 1) {
			for other in 0 .. (frequency_max + 1) {
				if depth + other < n {
					answer[depth + other] += i64(local_frequency[depth]) * frequency[other]
				}
			}
		}
		for depth in 1 .. (local_max + 1) {
			frequency[depth] += i64(local_frequency[depth])
		}
		if local_max > frequency_max {
			frequency_max = local_max
		}
	}

	for child in 0 .. n {
		if adjacent[centroid * max_n + child] && !removed[child] {
			solve_component(n, adjacent, mut removed, mut answer, child)
		}
	}
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

@[export: 'frequency_table_of_tree_distance']
pub fn frequency_table_of_tree_distance(input &i64, length usize,
	mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 1 || length > max_input_values {
		return -1
	}
	n_value := unsafe { input[0] }
	if n_value < 1 || n_value > max_n {
		return -1
	}
	n := int(n_value)
	if length != usize(1 + 2 * (n - 1)) {
		return -1
	}

	mut adjacent := []bool{len: max_n * max_n}
	mut dsu_parent := []int{len: max_n}
	mut dsu_size := []int{len: max_n, init: 1}
	for vertex in 0 .. n {
		dsu_parent[vertex] = vertex
	}
	for edge in 0 .. (n - 1) {
		offset := 1 + 2 * edge
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

	mut removed := []bool{len: max_n}
	mut answer := []i64{len: max_n}
	solve_component(n, adjacent, mut removed, mut answer, 0)
	required := 8 * (n - 1)
	if unsafe { output == nil } || capacity < usize(required) {
		return -2
	}
	for distance in 1 .. n {
		store_i64_le(mut output, 8 * (distance - 1), answer[distance])
	}
	return i64(required)
}
