module connected_components_with_dsu

const max_node_count = 256
const max_edge_count = 2047
const max_input_length = 2 + 2 * max_edge_count

fn find_root(mut parent []int, node int) int {
	mut current := node
	for parent[current] != current {
		parent[current] = parent[parent[current]]
		current = parent[current]
	}
	return current
}

@[export: 'connected_components_with_dsu']
pub fn connected_components_with_dsu(input &i64, length usize) i64 {
	if length < 2 || length > max_input_length { return -1 }
	unsafe {
		if input[0] < 0 || input[0] > max_node_count || input[1] < 0 || input[1] > max_edge_count { return -1 }
		node_count := int(input[0])
		edge_count := int(input[1])
		if int(length) != 2 + 2 * edge_count { return -1 }
		mut parent := []int{len: max_node_count + 1}
		mut set_size := []int{len: max_node_count + 1}
		for node in 1 .. node_count + 1 {
			parent[node] = node
			set_size[node] = 1
		}
		mut component_count := node_count
		for edge in 0 .. edge_count {
			left_arg := input[2 + 2 * edge]
			right_arg := input[3 + 2 * edge]
			if left_arg < 1 || left_arg > i64(node_count) || right_arg < 1 || right_arg > i64(node_count) { return -1 }
			mut left := find_root(mut parent, int(left_arg))
			mut right := find_root(mut parent, int(right_arg))
			if left == right { continue }
			if set_size[left] < set_size[right] {
				temporary := left
				left = right
				right = temporary
			}
			parent[right] = left
			set_size[left] += set_size[right]
			component_count--
		}
		return i64(component_count)
	}
}
