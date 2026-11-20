// Clean-room bounded edge-peeling truss decomposition.
@[export: 'k_truss_edge_peeling_decomposition']
pub fn k_truss_edge_peeling_decomposition(input &i64, length usize, output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > 243 { return -1 }
		n64 := input[0]
		m64 := input[1]
		if n64 < 1 || n64 > 16 || m64 < 0 || m64 > 120 || length != usize(2 + 2*m64) || length > 242 { return -1 }
		n := int(n64)
		m := int(m64)
		mut adjacent := [][]bool{len: 16, init: []bool{len: 16, init: false}}
		mut edge_index := [][]int{len: 16, init: []int{len: 16, init: -1}}
		mut edge_u := []int{len: 120, init: 0}
		mut edge_v := []int{len: 120, init: 0}
		mut support := []int{len: 120, init: 0}
		mut alive := []bool{len: 120, init: false}
		mut trussness := []i64{len: 120, init: 0}
		for edge in 0 .. m {
			u64 := input[2 + 2*edge]
			v64 := input[3 + 2*edge]
			if u64 < 0 || v64 <= u64 || v64 >= n64 { return -1 }
			u := int(u64)
			v := int(v64)
			if adjacent[u][v] { return -1 }
			adjacent[u][v] = true
			adjacent[v][u] = true
			edge_index[u][v] = edge
			edge_index[v][u] = edge
			edge_u[edge] = u
			edge_v[edge] = v
			alive[edge] = true
		}
		for u in 0 .. n {
			for v in u + 1 .. n {
				for w in v + 1 .. n {
					if adjacent[u][v] && adjacent[u][w] && adjacent[v][w] {
						support[edge_index[u][v]]++
						support[edge_index[u][w]]++
						support[edge_index[v][w]]++
					}
				}
			}
		}
		output_bytes := 8*m
		if output == nil || capacity < usize(output_bytes) { return -2 }
		mut remaining := m
		mut level := 0
		for remaining > 0 {
			mut selected := -1
			for edge in 0 .. m {
				if alive[edge] && (selected < 0 || support[edge] < support[selected]) { selected = edge }
			}
			if support[selected] > level { level = support[selected] }
			trussness[selected] = i64(level + 2)
			alive[selected] = false
			remaining--
			u := edge_u[selected]
			v := edge_v[selected]
			for w in 0 .. n {
				if w == u || w == v || !adjacent[u][w] || !adjacent[v][w] { continue }
				first := edge_index[u][w]
				second := edge_index[v][w]
				if alive[first] && alive[second] {
					if support[first] > level { support[first]-- }
					if support[second] > level { support[second]-- }
				}
			}
		}
		for edge in 0 .. m {
			bits := u64(trussness[edge])
			for byte in 0 .. 8 { output[8*edge+byte] = u8((bits >> (8*byte)) & 255) }
		}
		return i64(output_bytes)
	}
}
