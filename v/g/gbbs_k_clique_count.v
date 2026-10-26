// Clean-room GBBS fixed-k clique profile; see package LICENSE.txt.
@[export: 'gbbs_k_clique_count']
pub fn gbbs_k_clique_count(input &i64, length usize, output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > 130 { return -1 }
		n64 := input[0]
		m64 := input[1]
		if n64 < 1 || n64 > 24 || m64 < 0 || m64 > 64 { return -1 }
		n := int(n64)
		m := int(m64)
		if length != usize(2+2*m) { return -1 }
		mut adjacent := [][]bool{len: 24, init: []bool{len: 24, init: false}}
		mut degree := []int{len: 24, init: 0}
		for edge in 0 .. m {
			u64 := input[2+2*edge]
			v64 := input[3+2*edge]
			if u64 < 0 || v64 <= u64 || v64 >= n64 { return -1 }
			u := int(u64)
			v := int(v64)
			if adjacent[u][v] { return -1 }
			adjacent[u][v] = true
			adjacent[v][u] = true
			degree[u]++
			degree[v]++
		}
		if output == nil || capacity < 8 { return -2 }

		mut directed := [][]bool{len: 24, init: []bool{len: 24, init: false}}
		for u in 0 .. n {
			if degree[u] >= 3 {
				for v in u+1 .. n {
					if degree[v] >= 3 && adjacent[u][v] { directed[u][v] = true }
				}
			}
		}
		mut count := i64(0)
		for a in 0 .. n {
			for b in a+1 .. n {
				if !directed[a][b] { continue }
				for c in b+1 .. n {
					if !(directed[a][c] && directed[b][c]) { continue }
					for d in c+1 .. n {
						if directed[a][d] && directed[b][d] && directed[c][d] { count++ }
					}
				}
			}
		}
		bits := u64(count)
		for byte in 0 .. 8 { output[byte] = u8((bits >> (8*byte)) & 255) }
		return 8
	}
}
