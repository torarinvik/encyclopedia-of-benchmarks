module bondy_chvatal_hamiltonian_closure

const max_vertices = 8
const max_edges = 28
const max_input_words = 59
const max_output_words = 10

fn store_i64_le(output &u8, offset int, value i64) {
	unsafe {
		bits := u64(value)
		for byte in 0 .. 8 { output[offset + byte] = u8((bits >> (8 * byte)) & 255) }
	}
}

@[export: 'bondy_chvatal_hamiltonian_closure']
pub fn bondy_chvatal_hamiltonian_closure(input &i64, length usize, output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > max_input_words { return -1 }
		n_word, m_word := input[0], input[1]
		if n_word < 3 || n_word > max_vertices || m_word < 0 || m_word > max_edges { return -1 }
		n, m := int(n_word), int(m_word)
		if m > n * (n - 1) / 2 || length != usize(2 + 2 * m) { return -1 }

		mut adjacency := [max_vertices][max_vertices]bool{}
		for edge in 0 .. m {
			u_word, v_word := input[2 + 2 * edge], input[3 + 2 * edge]
			if u_word < 0 || u_word >= n_word || v_word < 0 || v_word >= n_word || u_word == v_word { return -1 }
			u, v := int(u_word), int(v_word)
			if adjacency[u][v] { return -1 }
			adjacency[u][v] = true
			adjacency[v][u] = true
		}

		mut added := 0
		for {
			mut degree := [max_vertices]int{}
			for u in 0 .. n {
				for v in 0 .. n { if adjacency[u][v] { degree[u]++ } }
			}
			mut chosen_u, mut chosen_v := n, n
			for u in 0 .. n {
				if chosen_u < n { break }
				for v in u + 1 .. n {
					if !adjacency[u][v] && degree[u] + degree[v] >= n {
						chosen_u, chosen_v = u, v
						break
					}
				}
			}
			if chosen_u == n { break }
			adjacency[chosen_u][chosen_v] = true
			adjacency[chosen_v][chosen_u] = true
			added++
		}

		mut staged := [max_output_words]i64{}
		full_mask := (1 << n) - 1
		mut complete := true
		for u in 0 .. n {
			mut row := 0
			for v in 0 .. n { if adjacency[u][v] { row |= 1 << v } }
			staged[2 + u] = i64(row)
			if row != (full_mask ^ (1 << u)) { complete = false }
		}
		if complete { staged[0] = 1 }
		staged[1] = i64(added)

		output_bytes := usize(2 + n) * 8
		if output == nil || capacity < output_bytes { return -2 }
		for word in 0 .. 2 + n { store_i64_le(output, word * 8, staged[word]) }
		return i64(output_bytes)
	}
}
