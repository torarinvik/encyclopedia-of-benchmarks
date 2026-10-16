module hamiltonian_cycle_exists

const max_vertices = 8
const max_input_length = 58

fn has_cycle(n int, graph []u8, mut visited []bool, current int, position int) bool {
	if position == n { return graph[current * max_vertices] != 0 }
	for next in 0 .. n {
		if graph[current * max_vertices + next] != 0 && !visited[next] {
			visited[next] = true
			if has_cycle(n, graph, mut visited, next, position + 1) { return true }
			visited[next] = false
		}
	}
	return false
}

@[export: 'hamiltonian_cycle_exists']
pub fn hamiltonian_cycle_exists(input &i64, length usize) i64 {
	if input == nil || length < 2 || length > max_input_length { return -1 }
	unsafe {
		n_value := input[0]
		m_value := input[1]
		if n_value < 3 || n_value > max_vertices || m_value < 0 { return -1 }
		n := int(n_value)
		if m_value > i64(n * (n - 1) / 2) { return -1 }
		m := int(m_value)
		if length != usize(2 + 2 * m) { return -1 }
		mut graph := []u8{len: max_vertices * max_vertices}
		for edge in 0 .. m {
			u_value := input[2 + 2 * edge]; v_value := input[3 + 2 * edge]
			if u_value < 0 || v_value < 0 || u_value >= n_value || v_value >= n_value || u_value == v_value { return -1 }
			u := int(u_value); v := int(v_value)
			if graph[u * max_vertices + v] != 0 { return -1 }
			graph[u * max_vertices + v] = 1
			graph[v * max_vertices + u] = 1
		}
		mut visited := []bool{len: max_vertices}
		visited[0] = true
		return if has_cycle(n, graph, mut visited, 0, 1) { 1 } else { 0 }
	}
}
