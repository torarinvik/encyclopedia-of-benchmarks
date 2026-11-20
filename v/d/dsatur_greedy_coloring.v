module dsatur_greedy_coloring

const max_vertices = 12
const max_edges = 66
const max_input_values = 134
const max_parseable_values = 135

fn dsatur_popcount(value_input u32) int {
	mut value := value_input
	mut count := 0
	for value != 0 {
		value &= value - u32(1)
		count++
	}
	return count
}

@[export: 'dsatur_greedy_coloring']
pub fn dsatur_greedy_coloring(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > max_parseable_values { return -1 }
		n_value, m_value := input[0], input[1]
		if n_value < 1 || n_value > max_vertices || m_value < 0 || m_value > max_edges { return -1 }
		max_possible_edges := n_value * (n_value - 1) / 2
		if m_value > max_possible_edges || length != usize(2 + 2 * m_value) || length > max_input_values { return -1 }
		n, m := int(n_value), int(m_value)
		mut adjacency := [max_vertices]u32{}
		for edge in 0 .. m {
			u_value, v_value := input[2 + 2 * edge], input[3 + 2 * edge]
			if u_value < 0 || v_value < 0 || u_value >= v_value || v_value >= n_value { return -1 }
			u, v := int(u_value), int(v_value)
			v_bit := u32(1) << v
			if adjacency[u] & v_bit != 0 { return -1 }
			adjacency[u] |= v_bit
			adjacency[v] |= u32(1) << u
		}

		mut colors := [max_vertices]int{}
		mut saturation := [max_vertices]u32{}
		mut residual_degree := [max_vertices]int{}
		for vertex in 0 .. n {
			colors[vertex] = -1
			residual_degree[vertex] = dsatur_popcount(adjacency[vertex])
		}
		mut color_count := 0
		for _ in 0 .. n {
			mut selected := -1
			mut selected_saturation := -1
			mut selected_degree := -1
			for vertex in 0 .. n {
				if colors[vertex] >= 0 { continue }
				sat_count := dsatur_popcount(saturation[vertex])
				degree := residual_degree[vertex]
				if sat_count > selected_saturation || (sat_count == selected_saturation && (degree > selected_degree || (degree == selected_degree && (selected < 0 || vertex < selected)))) {
					selected = vertex
					selected_saturation = sat_count
					selected_degree = degree
				}
			}
			mut color := 0
			for saturation[selected] & (u32(1) << color) != 0 { color++ }
			colors[selected] = color
			color_count = max(color_count, color + 1)
			color_bit := u32(1) << color
			for neighbor in 0 .. n {
				if colors[neighbor] < 0 && adjacency[selected] & (u32(1) << neighbor) != 0 {
					residual_degree[neighbor]--
					saturation[neighbor] |= color_bit
				}
			}
		}

		mut packed := u64(color_count) << 48
		for vertex in 0 .. n { packed |= u64(colors[vertex]) << (4 * vertex) }
		return i64(packed)
	}
}
