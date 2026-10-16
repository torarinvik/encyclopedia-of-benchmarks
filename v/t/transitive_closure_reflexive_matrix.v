module transitive_closure_reflexive_matrix

const max_vertices = 32
const max_edges = max_vertices * (max_vertices - 1)
const max_input_length = 2 + 2 * max_edges
const max_cells = max_vertices * max_vertices

fn put_i64_le(mut output &u8, offset int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'transitive_closure_reflexive_matrix']
pub fn transitive_closure_reflexive_matrix(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > max_input_length { return -1 }
	n_value := unsafe { input[0] }
	if n_value < 1 || n_value > max_vertices { return -1 }
	n := int(n_value)
	m_value := unsafe { input[1] }
	if m_value < 0 || m_value > i64(n * (n - 1)) { return -1 }
	m := int(m_value)
	if length != usize(2 + 2 * m) { return -1 }

	mut reach := [max_cells]i64{}
	for i in 0 .. n { reach[i * n + i] = 1 }
	unsafe {
		for edge in 0 .. m {
			from_value := input[2 + 2 * edge]
			to_value := input[3 + 2 * edge]
			if from_value < 0 || from_value >= i64(n) || to_value < 0 || to_value >= i64(n) || from_value == to_value { return -1 }
			from := int(from_value)
			to := int(to_value)
			if reach[from * n + to] != 0 { return -1 }
			reach[from * n + to] = 1
		}
	}
	for k in 0 .. n {
		for i in 0 .. n {
			if reach[i * n + k] == 1 {
				for j in 0 .. n { if reach[k * n + j] == 1 { reach[i * n + j] = 1 } }
			}
		}
	}
	output_bytes := n * n * 8
	if capacity < usize(output_bytes) || (output_bytes > 0 && unsafe { output == nil }) { return -2 }
	unsafe {
		for index in 0 .. n * n { put_i64_le(mut output, index * 8, reach[index]) }
	}
	return i64(output_bytes)
}
