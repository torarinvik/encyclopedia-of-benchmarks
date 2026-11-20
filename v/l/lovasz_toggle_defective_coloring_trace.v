module lovasz_toggle_defective_coloring_trace

import core:c

const max_input_length = 246

@[export: 'lovasz_toggle_defective_coloring_trace']
pub fn lovasz_toggle_defective_coloring_trace(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 5 || length > max_input_length { return -1 }
	unsafe {
		n_value, red_bound, blue_bound := input[0], input[1], input[2]
		if n_value < 0 || n_value > 16 || red_bound < 1 || red_bound > 8 || blue_bound < 1 || blue_bound > 8 { return -1 }
		n := int(n_value)
		red_mask_value := input[3]
		if red_mask_value < 0 || u64(red_mask_value) >= (u64(1) << n) { return -1 }
		m_value := input[4]
		if m_value < 0 || m_value > n_value * (n_value - 1) / 2 { return -1 }
		m := int(m_value)
		if length != usize(5 + 2 * m) { return -1 }

		mut adjacency := [16]u32{init: 0}
		mut degree := [16]int{init: 0}
		for edge in 0 .. m {
			offset := 5 + 2 * edge
			u_value, v_value := input[offset], input[offset + 1]
			if u_value < 0 || v_value <= u_value || v_value >= n_value { return -1 }
			u, v := int(u_value), int(v_value)
			v_bit := u32(1) << u32(v)
			u_bit := u32(1) << u32(u)
			if (adjacency[u] & v_bit) != 0 { return -1 }
			adjacency[u] |= v_bit
			adjacency[v] |= u_bit
			degree[u]++
			degree[v]++
		}
		for vertex in 0 .. n { if degree[vertex] > int(red_bound + blue_bound + 1) { return -1 } }

		mut red_mask := u64(red_mask_value)
		mut toggle_count := i64(0)
		for {
			mut bad_vertex := -1
			for vertex in 0 .. n {
				mut red_degree := 0
				for neighbor in 0 .. n {
					if (adjacency[vertex] & (u32(1) << u32(neighbor))) != 0 && (red_mask & (u64(1) << neighbor)) != 0 {
						red_degree++
					}
				}
				blue_degree := degree[vertex] - red_degree
				is_red := (red_mask & (u64(1) << vertex)) != 0
				if (is_red && red_degree > int(red_bound)) || (!is_red && blue_degree > int(blue_bound)) {
					bad_vertex = vertex
					break
				}
			}
			if bad_vertex < 0 { break }
			red_mask ^= u64(1) << bad_vertex
			toggle_count++
		}
		return (toggle_count << n) | i64(red_mask)
	}
}
