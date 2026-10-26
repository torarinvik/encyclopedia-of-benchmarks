// Clean-room bounded GBBS MPX low-diameter decomposition profile.
const gbbs_ldd_n = 12
const gbbs_ldd_m = 24
const gbbs_ldd_max_input = 50
const gbbs_ldd_batch = [13]int{1, 1, 1, 1, 2, 2, 3, 4, 4, 6, 7, 9, 11}

@[export: 'gbbs_low_diameter_decomposition']
pub fn gbbs_low_diameter_decomposition(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > gbbs_ldd_max_input { return -1 }
		n64 := input[0]
		m64 := input[1]
		if n64 < 1 || n64 > gbbs_ldd_n || m64 < 0 || m64 > gbbs_ldd_m ||
			length != usize(2 + 2*m64) { return -1 }
		n := int(n64)
		m := int(m64)
		mut adjacent := [][]bool{len: gbbs_ldd_n, init: []bool{len: gbbs_ldd_n, init: false}}
		for edge in 0 .. m {
			u64 := input[2 + 2*edge]
			v64 := input[3 + 2*edge]
			if u64 < 0 || u64 >= n64 || v64 <= u64 || v64 >= n64 { return -1 }
			u := int(u64)
			v := int(v64)
			if adjacent[u][v] { return -1 }
			adjacent[u][v] = true
			adjacent[v][u] = true
		}
		if output == nil || capacity < usize(n) { return -2 }
		mut label := []int{len: gbbs_ldd_n, init: -1}
		mut frontier := []int{len: gbbs_ldd_n, init: 0}
		mut frontier_count := 0
		mut cursor := 0
		mut assigned := 0
		mut round := 0
		for assigned < n {
			end := min(cursor + gbbs_ldd_batch[round], n)
			for candidate in cursor .. end {
				if label[candidate] < 0 {
					label[candidate] = candidate
					frontier[frontier_count] = candidate
					frontier_count++
					assigned++
				}
			}
			cursor = end
			if assigned == n { break }
			mut reached := []int{len: gbbs_ldd_n, init: -1}
			for i in 0 .. frontier_count {
				vertex := frontier[i]
				for neighbor in 0 .. n {
					if adjacent[vertex][neighbor] && label[neighbor] < 0 &&
						(reached[neighbor] < 0 || label[vertex] < reached[neighbor]) {
						reached[neighbor] = label[vertex]
					}
				}
			}
			frontier_count = 0
			for vertex in 0 .. n {
				if reached[vertex] >= 0 {
					label[vertex] = reached[vertex]
					frontier[frontier_count] = vertex
					frontier_count++
					assigned++
				}
			}
			round++
		}
		for vertex in 0 .. n { output[vertex] = u8(label[vertex]) }
		return i64(n)
	}
}
