module graph_c_undirected_simple

const max_vertices = 32
const max_edges = 2047

fn put_i64(output &u8, slot int, value i64) {
	bits := u64(value)
	unsafe { for byte in 0 .. 8 { output[slot * 8 + byte] = u8((bits >> u64(byte * 8)) & 255) } }
}

@[export: 'graph_c_undirected_simple']
pub fn graph_c_undirected_simple(input &i64, length usize, output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 2 { return -1 }
	unsafe {
		if input[0] < 1 || input[0] > max_vertices || input[1] < 0 || input[1] > max_edges { return -1 }
		vertices := int(input[0])
		edge_count := int(input[1])
		if length != usize(2 + 2 * edge_count) { return -1 }

		mut adjacency := [max_vertices * max_vertices]i64{init: 0}
		for edge in 0 .. edge_count {
			left_value := input[2 + 2 * edge]
			right_value := input[3 + 2 * edge]
			if left_value < 0 || right_value < 0 || left_value >= i64(vertices) || right_value >= i64(vertices) { return -1 }
			left := int(left_value)
			right := int(right_value)
			adjacency[left * vertices + right] = 1
			adjacency[right * vertices + left] = 1
		}
		count := vertices * vertices
		if output == nil || capacity < usize(count * 8) { return -2 }
		for row in 0 .. vertices {
			for column in 0 .. vertices { put_i64(output, row * vertices + column, adjacency[row * vertices + column]) }
		}
		return i64(count * 8)
	}
}
