@[export: 'lex_bfs']
pub fn lex_bfs(input &i64, length usize, output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > 243 { return -1 }
		n64 := input[0]
		m64 := input[1]
		start64 := input[2]
		if n64 < 1 || n64 > 16 || m64 < 0 || m64 > 120 || start64 < 0 ||
			start64 >= n64 || length != usize(3+2*m64) { return -1 }
		n := int(n64)
		m := int(m64)
		start := int(start64)
		mut adjacency := [][]bool{}
		mut labels := [][]i64{}
		for _ in 0 .. 16 {
			adjacency << []bool{len: 16, init: false}
			labels << []i64{len: 16, init: 0}
		}
		for edge in 0 .. m {
			u64 := input[3+2*edge]
			v64 := input[4+2*edge]
			if u64 < 0 || v64 <= u64 || v64 >= n64 { return -1 }
			u := int(u64)
			v := int(v64)
			if adjacency[u][v] { return -1 }
			adjacency[u][v] = true
			adjacency[v][u] = true
		}
		output_bytes := 8*n
		if output == nil || capacity < usize(output_bytes) { return -2 }
		mut label_len := []int{len: 16, init: 0}
		mut order := []i64{len: 16, init: 0}
		mut selected := []bool{len: 16, init: false}
		mut current := start
		for step in 0 .. n {
			if step > 0 {
				mut have_best := false
				for vertex in 0 .. n {
					if selected[vertex] { continue }
					if !have_best {
						current = vertex
						have_best = true
						continue
					}
					mut shared := label_len[vertex]
					if label_len[current] < shared { shared = label_len[current] }
					mut position := 0
					mut decided := false
					for position < shared {
						if labels[vertex][position] != labels[current][position] {
							if labels[vertex][position] > labels[current][position] { current = vertex }
							decided = true
							break
						}
						position++
					}
					if !decided && (label_len[vertex] > label_len[current] ||
						(label_len[vertex] == label_len[current] && vertex < current)) {
						current = vertex
					}
				}
			}
			selected[current] = true
			order[step] = i64(current)
			for neighbor in 0 .. n {
				if !adjacency[current][neighbor] || selected[neighbor] { continue }
				mut position := label_len[neighbor]
				for position > 0 {
					labels[neighbor][position] = labels[neighbor][position-1]
					position--
				}
				labels[neighbor][0] = i64(step)
				label_len[neighbor]++
			}
		}
		for index in 0 .. n {
			bits := u64(order[index])
			for byte in 0 .. 8 { output[8*index+byte] = u8((bits >> (8*byte)) & 255) }
		}
		return i64(output_bytes)
	}
}
