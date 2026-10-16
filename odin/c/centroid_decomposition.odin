package centroid_decomposition

import "core:c"

MAX_NODES :: 64
MAX_DIRECTED_EDGES :: 2 * (MAX_NODES - 1)
INVALID_PARENT :: -2

@(export)
centroid_decomposition :: proc "c" (values: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if values == nil || length < 1 || length > 2 * MAX_NODES - 1 do return -1
	if values[0] < 1 || values[0] > MAX_NODES do return -1
	node_count := int(values[0])
	if length != c.size_t(2 * node_count - 1) do return -1

	set_parent: [MAX_NODES]int
	head: [MAX_NODES]int
	edge_to: [MAX_DIRECTED_EDGES]int
	edge_next: [MAX_DIRECTED_EDGES]int
	edge_count := 0
	for node := 0; node < node_count; node += 1 {
		set_parent[node] = node
		head[node] = -1
	}
	position := c.size_t(1)
	for position < length {
		left_value := values[position]
		right_value := values[position + 1]
		if left_value < 0 || left_value >= i64(node_count) || right_value < 0 || right_value >= i64(node_count) || left_value == right_value do return -1
		left := int(left_value)
		right := int(right_value)
		left_root := left
		for set_parent[left_root] != left_root { left_root = set_parent[left_root] }
		right_root := right
		for set_parent[right_root] != right_root { right_root = set_parent[right_root] }
		if left_root == right_root do return -1
		set_parent[right_root] = left_root

		edge_to[edge_count] = right
		edge_next[edge_count] = head[left]
		head[left] = edge_count
		edge_count += 1
		edge_to[edge_count] = left
		edge_next[edge_count] = head[right]
		head[right] = edge_count
		edge_count += 1
		position += 2
	}
	if output_capacity < c.size_t(node_count * 4) || output == nil do return -2

	removed: [MAX_NODES]bool
	traversal_parent: [MAX_NODES]int
	subtree_size: [MAX_NODES]int
	order: [MAX_NODES]int
	stack: [MAX_NODES]int
	task_node: [MAX_NODES]int
	task_parent: [MAX_NODES]int
	decomposition_parent: [MAX_NODES]int
	for node := 0; node < node_count; node += 1 {
		removed[node] = false
		traversal_parent[node] = INVALID_PARENT
		decomposition_parent[node] = INVALID_PARENT
	}
	task_count := 1
	task_node[0] = 0
	task_parent[0] = -1
	for task_count > 0 {
		task_count -= 1
		start := task_node[task_count]
		centroid_parent := task_parent[task_count]
		for node := 0; node < node_count; node += 1 {
			traversal_parent[node] = INVALID_PARENT
		}
		stack_count := 1
		order_count := 0
		stack[0] = start
		traversal_parent[start] = -1
		for stack_count > 0 {
			stack_count -= 1
			node := stack[stack_count]
			order[order_count] = node
			order_count += 1
			subtree_size[node] = 1
			edge := head[node]
			for edge >= 0 {
				neighbor := edge_to[edge]
				if neighbor != traversal_parent[node] && !removed[neighbor] &&
					traversal_parent[neighbor] == INVALID_PARENT {
					traversal_parent[neighbor] = node
					stack[stack_count] = neighbor
					stack_count += 1
				}
				edge = edge_next[edge]
			}
		}

		index := order_count
		for index > 0 {
			index -= 1
			node := order[index]
			parent := traversal_parent[node]
			if parent >= 0 do subtree_size[parent] += subtree_size[node]
		}

		centroid := -1
		smallest_largest_branch := node_count + 1
		for order_index := 0; order_index < order_count; order_index += 1 {
			node := order[order_index]
			largest_branch := order_count - subtree_size[node]
			edge := head[node]
			for edge >= 0 {
				neighbor := edge_to[edge]
				if traversal_parent[neighbor] == node && subtree_size[neighbor] > largest_branch {
					largest_branch = subtree_size[neighbor]
				}
				edge = edge_next[edge]
			}
			if largest_branch < smallest_largest_branch ||
				(largest_branch == smallest_largest_branch && node < centroid) {
				centroid = node
				smallest_largest_branch = largest_branch
			}
		}

		decomposition_parent[centroid] = centroid_parent
		removed[centroid] = true
		edge := head[centroid]
		for edge >= 0 {
			neighbor := edge_to[edge]
			if !removed[neighbor] {
				task_node[task_count] = neighbor
				task_parent[task_count] = centroid
				task_count += 1
			}
			edge = edge_next[edge]
		}
	}

	for node := 0; node < node_count; node += 1 {
		bits := u32(decomposition_parent[node])
		output[4 * node] = u8(bits & 0xff)
		output[4 * node + 1] = u8((bits >> 8) & 0xff)
		output[4 * node + 2] = u8((bits >> 16) & 0xff)
		output[4 * node + 3] = u8((bits >> 24) & 0xff)
	}
	return i64(node_count)
}
