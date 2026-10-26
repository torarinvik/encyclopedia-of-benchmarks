// Clean-room bounded GBBS SCAN profile; see package LICENSE.txt.
@[export: 'gbbs_scan_structural_clustering']
pub fn gbbs_scan_structural_clustering(input &i64, length usize, output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > 130 { return -1 }
		n64 := input[0]
		m64 := input[1]
		if n64 < 1 || n64 > 16 || m64 < 0 || m64 > 64 { return -1 }
		n := int(n64)
		m := int(m64)
		if length != usize(2+2*m) { return -1 }
		mut adjacent := [][]bool{len: 16, init: []bool{len: 16, init: false}}
		mut degree := []int{len: 16, init: 0}
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
		output_bytes := 8*n
		if output == nil || capacity < usize(output_bytes) { return -2 }
		mut core := []bool{len: 16, init: false}
		mut labels := []i64{len: 16, init: -1}
		for u in 0 .. n {
			mut similar_count := 0
			for v in 0 .. n {
				if adjacent[u][v] {
					mut shared := 0
					for w in 0 .. 16 { if adjacent[u][w] && adjacent[v][w] { shared++ } }
					numerator := u64(shared+2)
					denominator_sq := u64((degree[u]+1)*(degree[v]+1))
					if 4*numerator*numerator >= denominator_sq { similar_count++ }
				}
			}
			core[u] = similar_count >= 2
		}
		for root in 0 .. n {
			if !core[root] || labels[root] != -1 { continue }
			mut queue := []int{len: 16, init: 0}
			mut head := 0
			mut tail := 1
			labels[root] = i64(root)
			queue[0] = root
			for head < tail {
				u := queue[head]
				head++
				for v in 0 .. n {
					if !core[v] || labels[v] != -1 || !adjacent[u][v] { continue }
					mut shared := 0
					for w in 0 .. 16 { if adjacent[u][w] && adjacent[v][w] { shared++ } }
					numerator := u64(shared+2)
					denominator_sq := u64((degree[u]+1)*(degree[v]+1))
					if 4*numerator*numerator >= denominator_sq {
						labels[v] = i64(root)
						queue[tail] = v
						tail++
					}
				}
			}
		}
		for u in 0 .. n {
			if core[u] { continue }
			mut best_core := 16
			mut best_num := u64(0)
			mut best_den := u64(1)
			for v in 0 .. n {
				if !core[v] || !adjacent[u][v] { continue }
				mut shared := 0
				for w in 0 .. 16 { if adjacent[u][w] && adjacent[v][w] { shared++ } }
				numerator := u64(shared+2)
				denominator_sq := u64((degree[u]+1)*(degree[v]+1))
				if 4*numerator*numerator < denominator_sq { continue }
				left := numerator*numerator*best_den
				right := best_num*best_num*denominator_sq
				if best_core == 16 || left > right || (left == right && v < best_core) {
					best_core = v
					best_num = numerator
					best_den = denominator_sq
				}
			}
			if best_core != 16 { labels[u] = labels[best_core] }
		}
		for v in 0 .. n {
			bits := u64(labels[v])
			for byte in 0 .. 8 { output[8*v+byte] = u8((bits >> (8*byte)) & 255) }
		}
		return i64(output_bytes)
	}
}
