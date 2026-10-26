// Clean-room bounded GBBS label-propagation profile; see package LICENSE.txt.
@[export: 'gbbs_label_propagation_clustering']
pub fn gbbs_label_propagation_clustering(input &i64, length usize, output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > 130 { return -1 }
		n64 := input[0]
		m64 := input[1]
		if n64 < 1 || n64 > 16 || m64 < 0 || m64 > 64 { return -1 }
		n := int(n64)
		m := int(m64)
		if length != usize(2+2*m) { return -1 }
		mut adjacent := [][]bool{len: 16, init: []bool{len: 16, init: false}}
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
		output_bytes := 8*n
		if output == nil || capacity < usize(output_bytes) { return -2 }
		mut labels := []i64{len: 16, init: 0}
		for vertex in 0 .. n { labels[vertex] = i64(vertex) }
		for u in 0 .. n {
			mut frequency := []int{len: 16, init: 0}
			mut degree := 0
			for v in 0 .. n {
				if adjacent[u][v] { frequency[int(labels[v])]++; degree++ }
			}
			if degree == 0 { continue }
			mut best_label := 0
			mut best_frequency := 0
			for label in 0 .. n {
				if frequency[label] > best_frequency ||
					(frequency[label] == best_frequency && frequency[label] > 0 && label > best_label) {
					best_label = label
					best_frequency = frequency[label]
				}
			}
			labels[u] = i64(best_label)
		}
		for vertex in 0 .. n {
			bits := u64(labels[vertex])
			for byte in 0 .. 8 { output[8*vertex+byte] = u8((bits >> (8*byte)) & 255) }
		}
		return i64(output_bytes)
	}
}
