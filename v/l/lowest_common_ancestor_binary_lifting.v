module lowest_common_ancestor_binary_lifting

const max_nodes = 256
const max_queries = 1024
const max_arcs = 510
const log_levels = 9

@[export: 'lowest_common_ancestor_binary_lifting']
pub fn lowest_common_ancestor_binary_lifting(values &i64, length usize, output &u8,
		output_capacity usize) i64 {
	if length < 4 { return -1 }
	node_count_value := unsafe { values[0] }
	if node_count_value < 1 || node_count_value > max_nodes { return -1 }
	node_count := int(node_count_value)
	root_value := unsafe { values[1] }
	edge_count_value := unsafe { values[2] }
	query_count_value := unsafe { values[3] }
	if root_value < 0 || root_value >= i64(node_count) || edge_count_value != i64(node_count - 1) ||
		query_count_value < 0 || query_count_value > max_queries { return -1 }
	edge_count := int(edge_count_value)
	query_count := int(query_count_value)
	query_offset := 4 + 2 * edge_count
	if length != usize(query_offset + 2 * query_count) { return -1 }
	root := int(root_value)

	mut head := [max_nodes]int{}
	mut arc_to := [max_arcs]int{}
	mut arc_next := [max_arcs]int{}
	mut parent := [max_nodes]int{}
	mut depth := [max_nodes]int{}
	mut up := [log_levels * max_nodes]int{}
	mut stack := [max_nodes]int{}
	for node in 0 .. node_count {
		head[node] = -1
		parent[node] = -2
	}
	mut arcs := 0
	for edge in 0 .. edge_count {
		left_value := unsafe { values[4 + 2 * edge] }
		right_value := unsafe { values[5 + 2 * edge] }
		if left_value < 0 || left_value >= i64(node_count) || right_value < 0 ||
			right_value >= i64(node_count) || left_value == right_value { return -1 }
		left := int(left_value)
		right := int(right_value)
		arc_to[arcs] = right
		arc_next[arcs] = head[left]
		head[left] = arcs
		arcs++
		arc_to[arcs] = left
		arc_next[arcs] = head[right]
		head[right] = arcs
		arcs++
	}
	for query in 0 .. query_count {
		for side in 0 .. 2 {
			node := unsafe { values[query_offset + 2 * query + side] }
			if node < 0 || node >= i64(node_count) { return -1 }
		}
	}

	mut top := 0
	mut reached := 0
	parent[root] = -1
	up[root] = root
	stack[top] = root
	top++
	for top > 0 {
		top--
		node := stack[top]
		reached++
		mut arc := head[node]
		for arc >= 0 {
			neighbor := arc_to[arc]
			if neighbor != parent[node] {
				if parent[neighbor] != -2 { return -1 }
				parent[neighbor] = node
				depth[neighbor] = depth[node] + 1
				up[neighbor] = node
				stack[top] = neighbor
				top++
			}
			arc = arc_next[arc]
		}
	}
	if reached != node_count { return -1 }
	if output_capacity < usize(query_count) { return -2 }
	for level in 1 .. log_levels {
		for node in 0 .. node_count {
			middle := up[(level - 1) * max_nodes + node]
			up[level * max_nodes + node] = up[(level - 1) * max_nodes + middle]
		}
	}
	for query in 0 .. query_count {
		mut u := int(unsafe { values[query_offset + 2 * query] })
		mut v := int(unsafe { values[query_offset + 2 * query + 1] })
		if depth[u] < depth[v] {
			temp := u
			u = v
			v = temp
		}
		difference := depth[u] - depth[v]
		for level in 0 .. log_levels {
			if difference & (1 << level) != 0 { u = up[level * max_nodes + u] }
		}
		if u != v {
			for level := log_levels - 1; level >= 0; level-- {
				up_u := up[level * max_nodes + u]
				up_v := up[level * max_nodes + v]
				if up_u != up_v {
					u = up_u
					v = up_v
				}
			}
			u = up[u]
		}
		unsafe { output[query] = u8(u) }
	}
	return i64(query_count)
}
