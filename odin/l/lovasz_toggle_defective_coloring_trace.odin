package lovasz_toggle_defective_coloring_trace

import "core:c"

@(export)
lovasz_toggle_defective_coloring_trace :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 5 || length > 246 do return -1
	n_value, red_bound, blue_bound := input[0], input[1], input[2]
	if n_value < 0 || n_value > 16 || red_bound < 1 || red_bound > 8 || blue_bound < 1 || blue_bound > 8 do return -1
	n := int(n_value)
	if input[3] < 0 do return -1
	red_mask := u64(input[3])
	if red_mask >= (u64(1) << n) do return -1
	m_value := input[4]
	if m_value < 0 || m_value > n_value * (n_value - 1) / 2 do return -1
	m := int(m_value)
	if length != c.size_t(5 + 2 * m) do return -1

	adjacency: [16]u32
	degree: [16]int
	for edge := 0; edge < m; edge += 1 {
		offset := c.size_t(5 + 2 * edge)
		u_value, v_value := input[offset], input[offset + 1]
		if u_value < 0 || v_value <= u_value || v_value >= n_value do return -1
		u, v := int(u_value), int(v_value)
		v_bit := u32(1) << u32(v)
		u_bit := u32(1) << u32(u)
		if (adjacency[u] & v_bit) != 0 do return -1
		adjacency[u] |= v_bit
		adjacency[v] |= u_bit
		degree[u] += 1
		degree[v] += 1
	}
	for vertex := 0; vertex < n; vertex += 1 {
		if degree[vertex] > int(red_bound + blue_bound + 1) do return -1
	}

	toggle_count := i64(0)
	for {
		bad := -1
		for vertex := 0; vertex < n; vertex += 1 {
			red_degree := 0
			for neighbor := 0; neighbor < n; neighbor += 1 {
				if (adjacency[vertex] & (u32(1) << u32(neighbor))) != 0 &&
					(red_mask & (u64(1) << neighbor)) != 0 {
					red_degree += 1
				}
			}
			blue_degree := degree[vertex] - red_degree
			is_red := (red_mask & (u64(1) << vertex)) != 0
			if (is_red && red_degree > int(red_bound)) || (!is_red && blue_degree > int(blue_bound)) {
				bad = vertex
				break
			}
		}
		if bad < 0 do break
		red_mask ^= u64(1) << bad
		toggle_count += 1
	}
	return toggle_count * (i64(1) << n) | i64(red_mask)
}
