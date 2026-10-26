// Clean-room bounded GBBS Goodrich-Pszona degeneracy-order profile.
@[export: 'gbbs_goodrich_pszona_degeneracy_order']
pub fn gbbs_goodrich_pszona_degeneracy_order(input &i64, length usize,
    output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > 382 { return -1 }
		n64 := input[0]
		m64 := input[1]
		if n64 < 1 || n64 > 20 || m64 < 0 || m64 > 190 { return -1 }
		n := int(n64)
		m := int(m64)
		if length != usize(2+2*m) { return -1 }
		mut adjacent := [][]bool{len: 20, init: []bool{len: 20, init: false}}
		for edge in 0 .. m {
			u64 := input[2+2*edge]
			v64 := input[3+2*edge]
			if u64 < 0 || v64 <= u64 || v64 >= n64 { return -1 }
			u := int(u64)
			v := int(v64)
			if adjacent[u][v] { return -1 }
			adjacent[u][v] = true
			adjacent[v][u] = true
		}
		if output == nil || capacity < 8*n { return -2 }
		mut degree := []int{len: 20, init: 0}
		mut remaining := []bool{len: 20, init: false}
		mut rank := []i64{len: 20, init: 0}
		for vertex in 0 .. n {
			remaining[vertex] = true
			for neighbor in 0 .. n {
				if adjacent[vertex][neighbor] { degree[vertex]++ }
			}
		}
		for position in 0 .. n {
			mut chosen := n
			for vertex in 0 .. n {
				if remaining[vertex] && (chosen == n || degree[vertex] < degree[chosen]) {
					chosen = vertex
				}
			}
			rank[chosen] = i64(position)
			remaining[chosen] = false
			for neighbor in 0 .. n {
				if remaining[neighbor] && adjacent[chosen][neighbor] { degree[neighbor]-- }
			}
		}
		for vertex in 0 .. n {
			bits := u64(rank[vertex])
			for byte in 0 .. 8 { output[8*vertex+byte] = u8((bits >> (8*byte)) & 255) }
		}
		return i64(8*n)
	}
}
