module cycle_check_directed_graph

// Directed cycle detection with iterative depth-first search and three colors.
@[export: 'cycle_check_directed_graph']
pub fn cycle_check_directed_graph(values &i64, length usize) i64 {
	if length == 0 || length > 65 || (length - 1) % 2 != 0 { return -1 }
	unsafe {
		if values[0] < 0 || values[0] > 64 { return -1 }
		vertices := usize(values[0])
		edge_count := (length - 1) / 2
		if edge_count > 32 { return -1 }
		mut adjacency := [64]u64{}
		mut state := [64]u8{}
		mut stack := [64]usize{}
		mut next_neighbor := [64]usize{}
		for edge := usize(0); edge < edge_count; edge++ {
			source_value := values[1 + 2 * edge]
			destination_value := values[2 + 2 * edge]
			if source_value < 0 || destination_value < 0 ||
				u64(source_value) >= u64(vertices) || u64(destination_value) >= u64(vertices) {
				return -1
			}
			source := usize(source_value)
			destination := usize(destination_value)
			adjacency[source] |= u64(1) << destination
		}
		for root := usize(0); root < vertices; root++ {
			if state[root] != 0 { continue }
			mut top := usize(0)
			stack[0] = root
			next_neighbor[0] = 0
			state[root] = 1
			for {
				node := stack[top]
				mut destination := next_neighbor[top]
				for destination < vertices && (adjacency[node] & (u64(1) << destination)) == 0 {
					destination++
				}
				if destination == vertices {
					state[node] = 2
					if top == 0 { break }
					top--
					continue
				}
				next_neighbor[top] = destination + 1
				if state[destination] == 1 { return 1 }
				if state[destination] == 0 {
					top++
					stack[top] = destination
					next_neighbor[top] = 0
					state[destination] = 1
				}
			}
		}
		return 0
	}
}
