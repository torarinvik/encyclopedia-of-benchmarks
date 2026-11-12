package chromatic_polynomial

import "core:c"

MAX_VERTICES :: 8
MAX_EDGES :: 16
MAX_INPUT_LENGTH :: 2 + 2 * MAX_EDGES

Adjacency :: [MAX_VERTICES]u64
Polynomial :: [MAX_VERTICES + 1]i64

chromatic_poly :: proc "contextless" (adjacency: Adjacency, n: int) -> Polynomial {
	result: Polynomial
	edge_u := n
	edge_v := n
	for u := 0; u < n && edge_u == n; u += 1 {
		for v := u + 1; v < n; v += 1 {
			if (adjacency[u] & (u64(1) << u64(v))) != 0 {
				edge_u = u
				edge_v = v
				break
			}
		}
	}
	if edge_u == n {
		result[n] = 1
		return result
	}

	deleted := adjacency
	deleted[edge_u] &= ~(u64(1) << u64(edge_v))
	deleted[edge_v] &= ~(u64(1) << u64(edge_u))
	without_edge := chromatic_poly(deleted, n)

	contracted: Adjacency
	for left := 0; left < n; left += 1 {
		for right := left + 1; right < n; right += 1 {
			if (adjacency[left] & (u64(1) << u64(right))) != 0 && !(left == edge_u && right == edge_v) {
				new_left := left
				new_right := right
				if new_left == edge_v do new_left = edge_u
				if new_right == edge_v do new_right = edge_u
				if new_left > edge_v do new_left -= 1
				if new_right > edge_v do new_right -= 1
				if new_left != new_right {
					contracted[new_left] |= u64(1) << u64(new_right)
					contracted[new_right] |= u64(1) << u64(new_left)
				}
			}
		}
	}
	with_edge_contracted := chromatic_poly(contracted, n - 1)
	for degree := 0; degree <= n; degree += 1 {
		result[degree] = without_edge[degree] - with_edge_contracted[degree]
	}
	return result
}

store_i64_le :: proc "contextless" (output: [^]u8, offset: c.size_t, value: i64) {
	bits := u64(value)
	for byte := c.size_t(0); byte < 8; byte += 1 {
		output[offset + byte] = u8(bits & 255)
		bits >>= 8
	}
}

@(export)
chromatic_polynomial :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > c.size_t(MAX_INPUT_LENGTH) do return -1
	n_value := input[0]
	m_value := input[1]
	if n_value < 0 || n_value > MAX_VERTICES || m_value < 0 || m_value > MAX_EDGES do return -1
	n := int(n_value)
	m := int(m_value)
	if length != c.size_t(2 + 2 * m) do return -1

	adjacency: Adjacency
	for edge := 0; edge < m; edge += 1 {
		u_value := input[2 + 2 * edge]
		v_value := input[3 + 2 * edge]
		if u_value < 0 || u_value >= n_value || v_value < 0 || v_value >= n_value || u_value == v_value do return -1
		u := int(u_value)
		v := int(v_value)
		if (adjacency[u] & (u64(1) << u64(v))) != 0 do return -1
		adjacency[u] |= u64(1) << u64(v)
		adjacency[v] |= u64(1) << u64(u)
	}

	output_bytes := 8 * (n + 1)
	if output == nil || capacity < c.size_t(output_bytes) do return -2
	coefficients := chromatic_poly(adjacency, n)
	for degree := 0; degree <= n; degree += 1 {
		store_i64_le(output, c.size_t(8 * degree), coefficients[degree])
	}
	return i64(output_bytes)
}
