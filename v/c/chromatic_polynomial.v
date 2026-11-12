module chromatic_polynomial

const max_vertices = 8
const max_edges = 16
const max_input_length = 2 + 2 * max_edges

fn chromatic_poly(adjacency [max_vertices]u64, n int) [max_vertices + 1]i64 {
	mut edge_u := n
	mut edge_v := n
	for u in 0 .. n {
		if edge_u == n {
			for v in u + 1 .. n {
				if (adjacency[u] & (u64(1) << v)) != 0 {
					edge_u = u
					edge_v = v
					break
				}
			}
		}
	}
	mut result := [max_vertices + 1]i64{}
	if edge_u == n {
		result[n] = 1
		return result
	}

	mut deleted := adjacency
	deleted[edge_u] &= ~(u64(1) << edge_v)
	deleted[edge_v] &= ~(u64(1) << edge_u)
	without_edge := chromatic_poly(deleted, n)

	mut contracted := [max_vertices]u64{}
	for left in 0 .. n {
		for right in left + 1 .. n {
			if (adjacency[left] & (u64(1) << right)) != 0 && !(left == edge_u && right == edge_v) {
				mut new_left := left
				mut new_right := right
				if new_left == edge_v { new_left = edge_u }
				if new_right == edge_v { new_right = edge_u }
				if new_left > edge_v { new_left-- }
				if new_right > edge_v { new_right-- }
				if new_left != new_right {
					contracted[new_left] |= u64(1) << new_right
					contracted[new_right] |= u64(1) << new_left
				}
			}
		}
	}
	with_edge_contracted := chromatic_poly(contracted, n - 1)
	for degree in 0 .. n + 1 {
		result[degree] = without_edge[degree] - with_edge_contracted[degree]
	}
	return result
}

fn store_i64_le(mut output &u8, offset int, value i64) {
	bits := u64(value)
	unsafe {
		for byte in 0 .. 8 {
			output[offset + byte] = u8(bits & 255)
			bits >>= 8
		}
	}
}

@[export: 'chromatic_polynomial']
pub fn chromatic_polynomial(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > max_input_length { return -1 }
	n_value := unsafe { input[0] }
	m_value := unsafe { input[1] }
	if n_value < 0 || n_value > max_vertices || m_value < 0 || m_value > max_edges { return -1 }
	n := int(n_value)
	m := int(m_value)
	if length != usize(2 + 2 * m) { return -1 }

	mut adjacency := [max_vertices]u64{}
	for edge in 0 .. m {
		u_value := unsafe { input[2 + 2 * edge] }
		v_value := unsafe { input[3 + 2 * edge] }
		if u_value < 0 || u_value >= n_value || v_value < 0 || v_value >= n_value || u_value == v_value { return -1 }
		u := int(u_value)
		v := int(v_value)
		if adjacency[u] & (u64(1) << v) != 0 { return -1 }
		adjacency[u] |= u64(1) << v
		adjacency[v] |= u64(1) << u
	}

	output_bytes := 8 * (n + 1)
	if unsafe { output == nil } || capacity < usize(output_bytes) { return -2 }
	coefficients := chromatic_poly(adjacency, n)
	for degree in 0 .. n + 1 {
		store_i64_le(mut output, 8 * degree, coefficients[degree])
	}
	return i64(output_bytes)
}
