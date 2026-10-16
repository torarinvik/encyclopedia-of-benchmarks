module directed_dfs_forest_count

const max_edge_count = 64
const max_vertex_id = i64(63)
const max_node_count = 128
const max_input_length = 1 + 2 * max_edge_count

fn find_last_node(label i64, labels &i64, node_count int) int {
	unsafe {
		mut found := max_node_count
		for node in 0 .. node_count {
			if labels[node] == label { found = node }
		}
		return found
	}
}

fn visit(current int, edge_count int, edge_starts &int, edge_ends &int, mut visited &bool) {
	unsafe {
		visited[current] = true
		for edge in 0 .. edge_count {
			destination := edge_ends[edge]
			if edge_starts[edge] == current && !visited[destination] {
				visit(destination, edge_count, edge_starts, edge_ends, mut visited)
			}
		}
	}
}

@[export: 'directed_dfs_forest_count']
pub fn directed_dfs_forest_count(input &i64, length usize) i64 {
	unsafe {
		if isnil(input) || length < 1 || length > max_input_length + 1 { return -1 }
		edge_count_value := input[0]
		if edge_count_value < 0 || edge_count_value > max_edge_count { return -1 }
		edge_count := int(edge_count_value)
		if length != usize(1 + 2 * edge_count) { return -1 }

		mut labels := [max_node_count]i64{}
		mut edge_starts := [max_edge_count]int{}
		mut edge_ends := [max_edge_count]int{}
		mut node_count := 0
		for edge in 0 .. edge_count {
			start_label, end_label := input[1 + 2 * edge], input[2 + 2 * edge]
			if start_label < 0 || start_label > max_vertex_id || end_label < 0 || end_label > max_vertex_id { return -1 }

			mut start := find_last_node(start_label, labels[0], node_count)
			mut ending := max_node_count
			if start_label == end_label {
				if start == max_node_count {
					start = node_count
					labels[node_count] = start_label
					node_count++
				}
				ending = node_count
				labels[node_count] = end_label
				node_count++
			} else {
				ending = find_last_node(end_label, labels[0], node_count)
				if start == max_node_count {
					start = node_count
					labels[node_count] = start_label
					node_count++
				}
				if ending == max_node_count {
					ending = node_count
					labels[node_count] = end_label
					node_count++
				}
			}
			edge_starts[edge] = start
			edge_ends[edge] = ending
		}

		mut marked := [max_node_count]bool{}
		mut roots := i64(0)
		for root in 0 .. node_count {
			if marked[root] { continue }
			mut visited := [max_node_count]bool{}
			visit(root, edge_count, edge_starts[0], edge_ends[0], mut visited[0])
			for node in 0 .. node_count {
				if visited[node] { marked[node] = true }
			}
			roots++
		}
		return roots
	}
}
