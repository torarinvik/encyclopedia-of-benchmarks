module welsh_powell

const max_vertices = 32
const max_edge_pairs = 512
const max_validation_length = 2 + 2 * max_edge_pairs + 1
const output_bytes_per_vertex = 8

fn vertex_bit(vertex int) u64 {
	return u64(1) << u64(vertex)
}

fn put_i64_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. output_bytes_per_vertex {
		unsafe { output[offset + byte] = u8(bits & u64(255)) }
		bits >>= 8
	}
}

@[export: 'welsh_powell']
pub fn welsh_powell(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if input == nil || length < 2 || length > usize(max_validation_length) { return -1 }
	unsafe {
		n64 := input[0]
		edge_count64 := input[1]
		if n64 < 0 || n64 > i64(max_vertices) || edge_count64 < 0 || edge_count64 > i64(max_edge_pairs) { return -1 }
		n := int(n64)
		edge_count := int(edge_count64)
		if length != usize(2 + 2 * edge_count) { return -1 }

		mut adjacency := [max_vertices]u64{}
		for edge in 0 .. edge_count {
			left64 := input[2 + 2 * edge]
			right64 := input[3 + 2 * edge]
			if left64 < 0 || left64 >= n64 || right64 < 0 || right64 >= n64 || left64 == right64 { return -1 }
			left := int(left64)
			right := int(right64)
			adjacency[left] |= vertex_bit(right)
			adjacency[right] |= vertex_bit(left)
		}

		output_bytes := n * output_bytes_per_vertex
		if output == nil || capacity < usize(output_bytes) { return -2 }

		mut degrees := [max_vertices]int{}
		mut order := [max_vertices]int{}
		mut colors := [max_vertices]i64{}
		for vertex in 0 .. n {
			colors[vertex] = -1
			order[vertex] = vertex
			for neighbor in 0 .. n {
				if (adjacency[vertex] & vertex_bit(neighbor)) != 0 { degrees[vertex]++ }
			}
		}

		// Stable descending degree order keeps equal-degree vertices by index.
		for index in 1 .. n {
			key := order[index]
			mut position := index
			for position > 0 && degrees[order[position - 1]] < degrees[key] {
				order[position] = order[position - 1]
				position--
			}
			order[position] = key
		}

		mut colored_vertices := u64(0)
		for index in 0 .. n {
			vertex := order[index]
			if colors[vertex] >= 0 { continue }
			mut used_colors := u64(0)
			for neighbor in 0 .. n {
				if (adjacency[vertex] & vertex_bit(neighbor)) != 0 && colors[neighbor] >= 0 {
					used_colors |= vertex_bit(int(colors[neighbor]))
				}
			}
			mut color := 0
			for (used_colors & vertex_bit(color)) != 0 { color++ }
			colors[vertex] = i64(color)
			colored_vertices |= vertex_bit(vertex)
			for other_index in 0 .. n {
				other := order[other_index]
				if colors[other] < 0 && (adjacency[other] & colored_vertices) == 0 {
					colors[other] = i64(color)
					colored_vertices |= vertex_bit(other)
				}
			}
		}

		for vertex in 0 .. n {
			put_i64_le(mut output, vertex * output_bytes_per_vertex, colors[vertex])
		}
		return i64(output_bytes)
	}
}
