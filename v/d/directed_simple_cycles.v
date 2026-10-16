module directed_simple_cycles

const max_vertices = 6
const max_edges = max_vertices * max_vertices
const max_output_bytes = 2786

@[export: 'directed_simple_cycles']
pub fn directed_simple_cycles(input &i64, length usize, output &u8, capacity usize) i64 {
	if length < 2 || unsafe { input == nil } { return -1 }
	vertex_value := unsafe { input[0] }
	edge_value := unsafe { input[1] }
	if vertex_value < 0 || vertex_value > max_vertices || edge_value < 0 || edge_value > max_edges { return -1 }
	vertices := int(vertex_value)
	edges := int(edge_value)
	if int(length) != 2 + 2 * edges { return -1 }

	mut adjacency := [max_vertices * max_vertices]bool{}
	for edge in 0 .. edges {
		source := unsafe { input[2 + 2 * edge] }
		destination := unsafe { input[3 + 2 * edge] }
		if source < 0 || source >= vertex_value || destination < 0 || destination >= vertex_value { return -1 }
		unsafe { adjacency[int(source) * max_vertices + int(destination)] = true }
	}

	mut scratch := [max_output_bytes]u8{}
	mut output_length := 0
	for start in 0 .. vertices {
		mut path := [max_vertices]int{}
		mut next_neighbor := [max_vertices]int{}
		mut visited := [max_vertices]bool{}
		mut depth := 0
		path[0] = start
		visited[start] = true
		for {
			current := path[depth]
			if next_neighbor[depth] == vertices {
				visited[current] = false
				if depth == 0 { break }
				depth--
				continue
			}
			neighbor := next_neighbor[depth]
			next_neighbor[depth]++
			if !unsafe { adjacency[current * max_vertices + neighbor] } { continue }
			if neighbor == start {
				for index in 0 .. depth + 1 {
					scratch[output_length] = u8(path[index])
					output_length++
				}
				scratch[output_length] = u8(start)
				output_length++
				scratch[output_length] = 255
				output_length++
			} else if !visited[neighbor] {
				depth++
				path[depth] = neighbor
				next_neighbor[depth] = 0
				visited[neighbor] = true
			}
		}
		for vertex in 0 .. vertices {
			unsafe {
				adjacency[start * max_vertices + vertex] = false
				adjacency[vertex * max_vertices + start] = false
			}
		}
	}
	if output_length == 0 { return 0 }
	if unsafe { isnil(output) } || capacity < usize(output_length) { return -2 }
	for index in 0 .. output_length { unsafe { output[index] = scratch[index] } }
	return i64(output_length)
}
