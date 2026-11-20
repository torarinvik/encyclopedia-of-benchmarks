// Minimum walk length covering all vertices via multi-source product BFS.
@[export: 'shortest_path_visiting_all_nodes']
pub fn shortest_path_visiting_all_nodes(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > 93 { return -1 }
		n_value := input[0]
		m_value := input[1]
		if n_value < 1 || n_value > 10 || m_value < 0 || m_value > 45 { return -1 }
		n := int(n_value)
		m := int(m_value)
		if m > n * (n - 1) / 2 || int(length) != 2 + 2 * m { return -1 }

		mut adjacency := [10]u16{}
		for edge in 0 .. m {
			u_value := input[2 + 2 * edge]
			v_value := input[3 + 2 * edge]
			if u_value < 0 || v_value < 0 || u_value >= n_value || v_value >= n_value || u_value == v_value { return -1 }
			u := int(u_value)
			v := int(v_value)
			u_bit := u16(1) << u
			v_bit := u16(1) << v
			if adjacency[u] & u_bit != 0 { return -1 }
			adjacency[u] |= u_bit
			adjacency[v] |= v_bit
		}

		mut reached := u16(1)
		for {
			previous := reached
			for vertex in 0 .. n {
				if reached & (u16(1) << vertex) != 0 { reached |= adjacency[vertex] }
			}
			if reached == previous { break }
		}
		full := (u16(1) << n) - u16(1)
		if reached != full { return -1 }

		state_count := (1 << n) * n
		mut distance := [10240]i16{}
		mut queue := [10240]u16{}
		for i in 0 .. state_count { distance[i] = -1 }
		mut head := 0
		mut tail := 0
		for start in 0 .. n {
			state := (1 << start) * n + start
			distance[state] = 0
			queue[tail] = u16(state)
			tail++
		}
		for head < tail {
			state := int(queue[head])
			head++
			mask := state / n
			vertex := state % n
			if mask == int(full) { return i64(distance[state]) }
			for next in 0 .. n {
				if adjacency[vertex] & (u16(1) << next) == 0 { continue }
				next_mask := mask | (1 << next)
				next_state := next_mask * n + next
				if distance[next_state] >= 0 { continue }
				distance[next_state] = distance[state] + 1
				queue[tail] = u16(next_state)
				tail++
			}
		}
		return -1
	}
}
