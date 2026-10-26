// Clean-room bounded GBBS k-core profile; see package LICENSE.txt.
@[export: 'gbbs_k_core_decomposition']
pub fn gbbs_k_core_decomposition(input &i64, length usize, output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > 130 { return -1 }
		n64 := input[0]
		m64 := input[1]
		if n64 < 1 || n64 > 16 || m64 < 0 || m64 > 64 || length != usize(2 + 2*m64) { return -1 }
		n := int(n64)
		m := int(m64)
		mut adjacent := [][]bool{len: 16, init: []bool{len: 16, init: false}}
		for edge in 0 .. m {
			u64 := input[2 + 2*edge]
			v64 := input[3 + 2*edge]
			if u64 < 0 || v64 <= u64 || v64 >= n64 { return -1 }
			u := int(u64)
			v := int(v64)
			if adjacent[u][v] { return -1 }
			adjacent[u][v] = true
			adjacent[v][u] = true
		}
		output_bytes := 8*n
		if output == nil || capacity < usize(output_bytes) { return -2 }
		mut degree := []int{len: 16, init: 0}
		mut core := []i64{len: 16, init: 0}
		mut alive := []bool{len: 16, init: false}
		mut shell := []bool{len: 16, init: false}
		for u in 0 .. n {
			alive[u] = true
			for v in 0 .. n { if adjacent[u][v] { degree[u]++ } }
		}
		mut remaining := n
		for remaining > 0 {
			mut k := n
			for u in 0 .. n { if alive[u] && degree[u] < k { k = degree[u] } }
			for u in 0 .. n {
				shell[u] = alive[u] && degree[u] == k
				if shell[u] { alive[u] = false; core[u] = i64(k); remaining-- }
			}
			for v in 0 .. n {
				if !alive[v] { continue }
				mut removed := 0
				for u in 0 .. n { if shell[u] && adjacent[u][v] { removed++ } }
				if removed > 0 { degree[v] = max(degree[v] - removed, k) }
			}
		}
		for u in 0 .. n {
			bits := u64(core[u])
			for byte in 0 .. 8 { output[8*u+byte] = u8((bits >> (8*byte)) & 255) }
		}
		return i64(output_bytes)
	}
}
