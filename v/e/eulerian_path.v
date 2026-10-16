module eulerian_path

fn put_i64(output &u8, byte_offset int, value i64) {
	bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[byte_offset + byte] = u8(bits >> (byte * 8)) }
	}
}

// Construct a directed Eulerian path with iterative Hierholzer traversal.
@[export: 'eulerian_path']
pub fn eulerian_path(input &i64, length usize, output &u8, capacity usize) i64 {
	if length < 2 || unsafe { input == nil } { return -1 }
	unsafe {
		vertex_value := input[0]
		edge_value := input[1]
		if vertex_value < 0 || vertex_value > 32 || edge_value < 0 || edge_value > 256 { return -1 }
		vertices := int(vertex_value)
		edges := int(edge_value)
		if int(length) != 2 + 2 * edges { return -1 }

		mut adjacency := [32][256]u8{}
		mut in_degree := [32]int{}
		mut out_degree := [32]int{}
		for edge in 0 .. edges {
			source := input[2 + 2 * edge]
			destination := input[3 + 2 * edge]
			if source < 0 || source >= vertex_value || destination < 0 || destination >= vertex_value { return -1 }
			source_index := int(source)
			destination_index := int(destination)
			adjacency[source_index][out_degree[source_index]] = u8(destination_index)
			out_degree[source_index]++
			in_degree[destination_index]++
		}
		if edges == 0 { return 0 }

		mut start := 0
		mut start_count := 0
		mut end_count := 0
		for vertex in 0 .. vertices {
			difference := out_degree[vertex] - in_degree[vertex]
			if difference == 1 {
				start = vertex
				start_count++
			} else if difference == -1 {
				end_count++
			} else if difference != 0 { return 0 }
		}
		if !((start_count == 0 && end_count == 0) || (start_count == 1 && end_count == 1)) { return 0 }
		if start_count == 0 {
			for start < vertices && out_degree[start] == 0 { start++ }
			if start == vertices { return 0 }
		}

		mut remaining := [32]int{}
		for vertex in 0 .. vertices { remaining[vertex] = out_degree[vertex] }
		mut stack := [257]int{}
		mut reverse_path := [257]int{}
		mut top := 1
		mut path_count := 0
		stack[0] = start
		for top > 0 {
			current := stack[top - 1]
			if remaining[current] > 0 {
				remaining[current]--
				next := int(adjacency[current][remaining[current]])
				stack[top] = next
				top++
			} else {
				top--
				reverse_path[path_count] = stack[top]
				path_count++
			}
		}
		if path_count != edges + 1 { return 0 }
		bytes := path_count * 8
		if isnil(output) || capacity < usize(bytes) { return -2 }
		for index in 0 .. path_count { put_i64(output, index * 8, i64(reverse_path[path_count - index - 1])) }
		return i64(bytes)
	}
}
