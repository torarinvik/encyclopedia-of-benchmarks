// Clean-room bounded GBBS Barenboim-Elkin degeneracy-order profile.
@[export: 'gbbs_barenboim_elkin_degeneracy_order']
pub fn gbbs_barenboim_elkin_degeneracy_order(input &i64, length usize,
	mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > 382 { return -1 }
		n64 := input[0]
		m64 := input[1]
		if n64 < 1 || n64 > 20 || m64 < 0 || m64 > 190 { return -1 }
		n := int(n64)
		m := int(m64)
		if length != usize(2 + 2*m) { return -1 }
		mut adjacent := [][]bool{len: 20, init: []bool{len: 20, init: false}}
		mut initial_degree := []int{len: 20, init: 0}
		for edge in 0 .. m {
			u64 := input[2 + 2*edge]
			v64 := input[3 + 2*edge]
			if u64 < 0 || u64 >= v64 || v64 >= n64 { return -1 }
			u := int(u64)
			v := int(v64)
			if adjacent[u][v] { return -1 }
			adjacent[u][v] = true
			adjacent[v][u] = true
			initial_degree[u]++
			initial_degree[v]++
		}
		if output == nil || capacity < 8*n { return -2 }
		mut degree := []int{len: 20, init: 0}
		mut alive := []bool{len: 20, init: false}
		for v in 0 .. n { degree[v] = initial_degree[v]; alive[v] = true }
		mut remaining := n
		mut best_num := 0
		mut best_den := 1
		for remaining > 0 {
			mut total := 0
			for v in 0 .. n { if alive[v] { total += degree[v] } }
			if total*best_den > best_num*remaining { best_num = total; best_den = remaining }
			mut removed := []bool{len: 20, init: false}
			mut count := 0
			for v in 0 .. n {
				if alive[v] && 10*degree[v]*remaining <= 11*total { removed[v] = true; count++ }
			}
			if count == 0 { return -1 }
			for v in 0 .. n { if removed[v] { alive[v] = false } }
			remaining -= count
			for v in 0 .. n {
				if alive[v] {
					mut decrement := 0
					for u in 0 .. n { if removed[u] && adjacent[v][u] { decrement++ } }
					degree[v] -= decrement
				}
			}
		}
		mut cutoff := (best_num + 10*best_den - 1) / (10*best_den)
		if cutoff < 1 { cutoff = 1 }
		for v in 0 .. n { degree[v] = initial_degree[v]; alive[v] = true }
		mut order := []int{len: 20, init: 0}
		mut used := 0
		for used < n {
			mut shell := []int{len: 20, init: 0}
			mut count := 0
			for v in 0 .. n { if alive[v] && degree[v] < cutoff { shell[count] = v; count++ } }
			if count == 0 {
				for v in 0 .. n { if alive[v] { shell[count] = v; count++; break } }
			}
			for i in 0 .. count { alive[shell[i]] = false; order[used] = shell[i]; used++ }
			for v in 0 .. n {
				if alive[v] {
					mut decrement := 0
					for i in 0 .. count { if adjacent[v][shell[i]] { decrement++ } }
					degree[v] -= decrement
				}
			}
		}
		mut rank := []i64{len: 20, init: 0}
		for i in 0 .. n { rank[order[i]] = i64(i) }
		for v in 0 .. n {
			bits := u64(rank[v])
			for byte in 0 .. 8 { output[8*v+byte] = u8((bits >> (8*byte)) & 255) }
		}
		return i64(8*n)
	}
}
