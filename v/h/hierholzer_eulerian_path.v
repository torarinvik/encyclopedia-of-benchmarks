module hierholzer_eulerian_path

const max_vertices = 16
const max_edges = 48
const max_input_length = 98
const max_route = 49

fn write_i64_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 {
		output[offset + byte] = u8(bits & 255)
		bits >>= 8
	}
}

@[export: 'hierholzer_eulerian_path']
pub fn hierholzer_eulerian_path(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > max_input_length { return -1 }
		vertex_count_value := input[0]
		edge_count_value := input[1]
		if vertex_count_value < 0 || vertex_count_value > max_vertices ||
			edge_count_value < 0 || edge_count_value > max_edges { return -1 }
		vertex_count := int(vertex_count_value)
		edge_count := int(edge_count_value)
		if length != usize(2 + 2 * edge_count) { return -1 }

		mut adjacency := [max_vertices][max_edges]int{}
		mut in_degree := [max_vertices]int{}
		mut out_degree := [max_vertices]int{}
		for edge in 0 .. edge_count {
			source_value := input[2 + 2 * edge]
			destination_value := input[3 + 2 * edge]
			if source_value < 0 || source_value >= vertex_count_value ||
				destination_value < 0 || destination_value >= vertex_count_value { return -1 }
			source := int(source_value)
			destination := int(destination_value)
			adjacency[source][out_degree[source]] = destination
			out_degree[source]++
			in_degree[destination]++
		}

		mut path := [max_route]int{}
		mut path_length := 0
		if vertex_count == 0 {
			path_length = 0
		} else if edge_count == 0 {
			path[0] = 0
			path_length = 1
		} else {
			mut start := -1
			mut start_count := 0
			mut end_count := 0
			mut degrees_valid := true
			for vertex in 0 .. vertex_count {
				difference := out_degree[vertex] - in_degree[vertex]
				if difference == 1 { start = vertex; start_count++ }
				else if difference == -1 { end_count++ }
				else if difference < -1 || difference > 1 { degrees_valid = false }
			}
			if !((start_count == 1 && end_count == 1) ||
				(start_count == 0 && end_count == 0)) { degrees_valid = false }
			if degrees_valid && start < 0 {
				for vertex in 0 .. vertex_count {
					if out_degree[vertex] > 0 { start = vertex; break }
				}
			}

			mut connected := degrees_valid
			if connected {
				mut visited := [max_vertices]bool{}
				mut pending := [max_vertices]int{}
				mut pending_head := 0
				mut pending_tail := 1
				pending[0] = start
				visited[start] = true
				for pending_head < pending_tail {
					current := pending[pending_head]
					pending_head++
					for edge in 0 .. out_degree[current] {
						next := adjacency[current][edge]
						if !visited[next] {
							visited[next] = true
							pending[pending_tail] = next
							pending_tail++
						}
					}
					for source in 0 .. vertex_count {
						if visited[source] { continue }
						for edge in 0 .. out_degree[source] {
							if adjacency[source][edge] == current {
								visited[source] = true
								pending[pending_tail] = source
								pending_tail++
								break
							}
						}
					}
				}
				for vertex in 0 .. vertex_count {
					if in_degree[vertex] + out_degree[vertex] > 0 && !visited[vertex] { connected = false }
				}
			}

			if connected {
				mut next_position := [max_vertices]int{}
				mut stack := [max_route]int{}
				mut reverse_path := [max_route]int{}
				mut stack_size := 1
				mut reverse_length := 0
				stack[0] = start
				for stack_size > 0 {
					current := stack[stack_size - 1]
					if next_position[current] < out_degree[current] {
						next := adjacency[current][next_position[current]]
						next_position[current]++
						stack[stack_size] = next
						stack_size++
					} else {
					stack_size--
					reverse_path[reverse_length] = stack[stack_size]
					reverse_length++
					}
				}
				if reverse_length == edge_count + 1 {
					path_length = reverse_length
					for index in 0 .. path_length { path[index] = reverse_path[path_length - 1 - index] }
				}
			}
		}

		output_bytes := 8 * (path_length + 1)
		if output == nil || capacity < usize(output_bytes) { return -2 }
		write_i64_le(mut output, 0, i64(path_length))
		for index in 0 .. path_length { write_i64_le(mut output, 8 * (index + 1), i64(path[index])) }
		return i64(output_bytes)
	}
}
