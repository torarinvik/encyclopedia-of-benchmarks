package hierholzer_eulerian_path

import "core:c"

MAX_VERTICES :: 16
MAX_EDGES :: 48
MAX_INPUT_LENGTH :: 98
MAX_ROUTE :: 49

write_i64_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8(bits & 255)
		bits >>= 8
	}
}

@(export, link_name="hierholzer_eulerian_path")
hierholzer_eulerian_path :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > c.size_t(MAX_INPUT_LENGTH) do return -1
	vertex_count_value, edge_count_value := input[0], input[1]
	if vertex_count_value < 0 || vertex_count_value > MAX_VERTICES ||
		edge_count_value < 0 || edge_count_value > MAX_EDGES do return -1
	vertex_count, edge_count := int(vertex_count_value), int(edge_count_value)
	if length != c.size_t(2 + 2 * edge_count) do return -1

	var adjacency: [MAX_VERTICES][MAX_EDGES]int
	var in_degree: [MAX_VERTICES]int
	var out_degree: [MAX_VERTICES]int
	for edge := 0; edge < edge_count; edge += 1 {
		source_value, destination_value := input[2 + 2 * edge], input[3 + 2 * edge]
		if source_value < 0 || source_value >= vertex_count_value ||
			destination_value < 0 || destination_value >= vertex_count_value do return -1
		source, destination := int(source_value), int(destination_value)
		adjacency[source][out_degree[source]] = destination
		out_degree[source] += 1
		in_degree[destination] += 1
	}

	var path: [MAX_ROUTE]int
	path_length := 0
	if vertex_count == 0 {
		path_length = 0
	} else if edge_count == 0 {
		path[0] = 0
		path_length = 1
	} else {
		start := -1
		start_count, end_count := 0, 0
		degrees_valid := true
		for vertex := 0; vertex < vertex_count; vertex += 1 {
			difference := out_degree[vertex] - in_degree[vertex]
			if difference == 1 { start = vertex; start_count += 1 }
			else if difference == -1 { end_count += 1 }
			else if difference < -1 || difference > 1 { degrees_valid = false }
		}
		if !((start_count == 1 && end_count == 1) || (start_count == 0 && end_count == 0)) {
			degrees_valid = false
		}
		if degrees_valid && start < 0 {
			for vertex := 0; vertex < vertex_count; vertex += 1 {
				if out_degree[vertex] > 0 { start = vertex; break }
			}
		}

		connected := degrees_valid
		if connected {
			var visited: [MAX_VERTICES]bool
			var pending: [MAX_VERTICES]int
			pending_head, pending_tail := 0, 1
			pending[0] = start
			visited[start] = true
			for pending_head < pending_tail {
				current := pending[pending_head]
				pending_head += 1
				for edge := 0; edge < out_degree[current]; edge += 1 {
					next := adjacency[current][edge]
					if !visited[next] { visited[next] = true; pending[pending_tail] = next; pending_tail += 1 }
				}
				for source := 0; source < vertex_count; source += 1 {
					if visited[source] { continue }
					for edge := 0; edge < out_degree[source]; edge += 1 {
						if adjacency[source][edge] == current {
							visited[source] = true
							pending[pending_tail] = source
							pending_tail += 1
							break
						}
					}
				}
			}
			for vertex := 0; vertex < vertex_count; vertex += 1 {
				if in_degree[vertex] + out_degree[vertex] > 0 && !visited[vertex] { connected = false }
			}
		}

		if connected {
			var next_position: [MAX_VERTICES]int
			var stack, reverse_path: [MAX_ROUTE]int
			stack_size, reverse_length := 1, 0
			stack[0] = start
			for stack_size > 0 {
				current := stack[stack_size - 1]
				if next_position[current] < out_degree[current] {
					next := adjacency[current][next_position[current]]
					next_position[current] += 1
					stack[stack_size] = next
					stack_size += 1
				} else {
				stack_size -= 1
				reverse_path[reverse_length] = stack[stack_size]
				reverse_length += 1
				}
			}
			if reverse_length == edge_count + 1 {
				path_length = reverse_length
				for index := 0; index < path_length; index += 1 {
					path[index] = reverse_path[path_length - 1 - index]
				}
			}
		}
	}

	output_bytes := 8 * (path_length + 1)
	if output == nil || capacity < c.size_t(output_bytes) do return -2
	write_i64_le(output, 0, i64(path_length))
	for index := 0; index < path_length; index += 1 {
		write_i64_le(output, 8 * (index + 1), i64(path[index]))
	}
	return i64(output_bytes)
}
