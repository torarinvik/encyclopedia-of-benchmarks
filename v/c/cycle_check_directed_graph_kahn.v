module cycle_check_directed_graph_kahn

// Directed cycle detection with Kahn's zero-indegree queue.
@[export: 'cycle_check_directed_graph_kahn']
pub fn cycle_check_directed_graph_kahn(values &i64, length usize) i64 {
	if length == 0 || length > 65 || (length - 1) % 2 != 0 { return -1 }
	unsafe {
		if values[0] < 0 || values[0] > 64 { return -1 }
		vertices := usize(values[0])
		edge_count := (length - 1) / 2
		if edge_count > 32 { return -1 }
		mut adjacency := [64]u64{}
		mut indegree := [64]usize{}
		for edge := usize(0); edge < edge_count; edge++ {
			source_value := values[1 + 2 * edge]
			destination_value := values[2 + 2 * edge]
			if source_value < 0 || destination_value < 0 ||
				u64(source_value) >= u64(vertices) || u64(destination_value) >= u64(vertices) {
				return -1
			}
			source := usize(source_value)
			destination := usize(destination_value)
			mask := u64(1) << destination
			if adjacency[source] & mask == 0 {
				adjacency[source] |= mask
				indegree[destination]++
			}
		}
		mut queue := [64]usize{}
		mut head := usize(0)
		mut tail := usize(0)
		for vertex := usize(0); vertex < vertices; vertex++ {
			if indegree[vertex] == 0 {
				queue[tail] = vertex
				tail++
			}
		}
		mut removed := usize(0)
		for head < tail {
			source := queue[head]
			head++
			removed++
			for destination := usize(0); destination < vertices; destination++ {
				if adjacency[source] & (u64(1) << destination) != 0 {
					indegree[destination]--
					if indegree[destination] == 0 {
						queue[tail] = destination
						tail++
					}
				}
			}
		}
		if removed != vertices { return 1 }
		return 0
	}
}
