const max_nodes = 64
const max_directed_edges = 2 * (max_nodes - 1)
const invalid_parent = -2

@[export: 'centroid_decomposition']
pub fn centroid_decomposition(values &i64, length usize, output &u8, output_capacity usize) i64 {
	if unsafe { values == nil } || length < 1 || length > 2 * max_nodes - 1 { return -1 }
	side_value := unsafe { values[0] }
	if side_value < 1 || side_value > max_nodes { return -1 }
	node_count := int(side_value)
	if length != usize(2 * node_count - 1) { return -1 }

	mut set_parent := [max_nodes]int{init: 0}
	mut head := [max_nodes]int{init: -1}
	mut edge_to := [max_directed_edges]int{init: 0}
	mut edge_next := [max_directed_edges]int{init: -1}
	for node := 0; node < node_count; node++ {
		set_parent[node] = node
	}
	mut edge_count := 0
	mut position := usize(1)
	for position < length {
		left_value := unsafe { values[position] }
		right_value := unsafe { values[position + 1] }
		if left_value < 0 || left_value >= i64(node_count) || right_value < 0
			|| right_value >= i64(node_count) || left_value == right_value { return -1 }
		left := int(left_value)
		right := int(right_value)
		mut left_root := left
		for set_parent[left_root] != left_root { left_root = set_parent[left_root] }
		mut right_root := right
		for set_parent[right_root] != right_root { right_root = set_parent[right_root] }
		if left_root == right_root { return -1 }
		set_parent[right_root] = left_root

		edge_to[edge_count] = right
		edge_next[edge_count] = head[left]
		head[left] = edge_count
		edge_count++
		edge_to[edge_count] = left
		edge_next[edge_count] = head[right]
		head[right] = edge_count
		edge_count++
		position += 2
	}
	if output_capacity < usize(node_count * 4) || unsafe { output == nil } { return -2 }

	mut removed := [max_nodes]bool{}
	mut traversal_parent := [max_nodes]int{init: invalid_parent}
	mut subtree_size := [max_nodes]int{}
	mut order := [max_nodes]int{}
	mut stack := [max_nodes]int{}
	mut task_node := [max_nodes]int{}
	mut task_parent := [max_nodes]int{}
	mut decomposition_parent := [max_nodes]int{init: invalid_parent}
	mut task_count := 1
	task_node[0] = 0
	task_parent[0] = -1
	for task_count > 0 {
		task_count--
		start := task_node[task_count]
		centroid_parent := task_parent[task_count]
		for node := 0; node < node_count; node++ { traversal_parent[node] = invalid_parent }
		mut stack_count := 1
		mut order_count := 0
		stack[0] = start
		traversal_parent[start] = -1
		for stack_count > 0 {
			stack_count--
			node := stack[stack_count]
			order[order_count] = node
			order_count++
			subtree_size[node] = 1
			mut edge := head[node]
			for edge >= 0 {
				neighbor := edge_to[edge]
				if neighbor != traversal_parent[node] && !removed[neighbor]
					&& traversal_parent[neighbor] == invalid_parent {
					traversal_parent[neighbor] = node
					stack[stack_count] = neighbor
					stack_count++
				}
				edge = edge_next[edge]
			}
		}

		mut index := order_count
		for index > 0 {
			index--
			node := order[index]
			parent := traversal_parent[node]
			if parent >= 0 { subtree_size[parent] += subtree_size[node] }
		}

		mut centroid := -1
		mut smallest_largest_branch := node_count + 1
		for order_index := 0; order_index < order_count; order_index++ {
			node := order[order_index]
			mut largest_branch := order_count - subtree_size[node]
			mut edge := head[node]
			for edge >= 0 {
				neighbor := edge_to[edge]
				if traversal_parent[neighbor] == node && subtree_size[neighbor] > largest_branch {
					largest_branch = subtree_size[neighbor]
				}
				edge = edge_next[edge]
			}
			if largest_branch < smallest_largest_branch
				|| (largest_branch == smallest_largest_branch && node < centroid) {
				centroid = node
				smallest_largest_branch = largest_branch
			}
		}

		decomposition_parent[centroid] = centroid_parent
		removed[centroid] = true
		mut edge := head[centroid]
		for edge >= 0 {
			neighbor := edge_to[edge]
			if !removed[neighbor] {
				task_node[task_count] = neighbor
				task_parent[task_count] = centroid
				task_count++
			}
			edge = edge_next[edge]
		}
	}

	for node := 0; node < node_count; node++ {
		parent := decomposition_parent[node]
		bits := u32(parent)
		unsafe { output[4 * node] = u8(bits & 255) }
		unsafe { output[4 * node + 1] = u8((bits >> 8) & 255) }
		unsafe { output[4 * node + 2] = u8((bits >> 16) & 255) }
		unsafe { output[4 * node + 3] = u8((bits >> 24) & 255) }
	}
	return i64(node_count)
}
