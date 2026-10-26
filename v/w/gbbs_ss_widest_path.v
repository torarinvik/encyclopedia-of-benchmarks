// Clean-room bounded GBBS widest-path profile; see package LICENSE.txt.
@[export: 'gbbs_ss_widest_path']
pub fn gbbs_ss_widest_path(input &i64, length usize, output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > 195 { return -1 }
		n64 := input[0]
		m64 := input[1]
		source64 := input[2]
		if n64 < 1 || n64 > 16 || m64 < 0 || m64 > 64 || source64 < 0 || source64 >= n64 || length != usize(3+3*m64) { return -1 }
		n := int(n64)
		m := int(m64)
		source := int(source64)
		mut edge_from := []int{len: 64, init: 0}
		mut edge_to := []int{len: 64, init: 0}
		mut edge_capacity := []i64{len: 64, init: 0}
		for edge in 0 .. m {
			from := input[3+3*edge]
			to := input[4+3*edge]
			edge_width := input[5+3*edge]
			if from < 0 || from >= n64 || to < 0 || to >= n64 || edge_width < 1 || edge_width > 32 { return -1 }
			edge_from[edge] = int(from)
			edge_to[edge] = int(to)
			edge_capacity[edge] = edge_width
		}
		output_bytes := 8*n
		if output == nil || capacity < usize(output_bytes) { return -2 }
		mut width := []i64{len: 16, init: 0}
		mut settled := []bool{len: 16, init: false}
		width[source] = 2147483647
		for _ in 0 .. n {
			mut u := -1
			for vertex in 0 .. n {
				if !settled[vertex] && (u < 0 || width[vertex] > width[u]) { u = vertex }
			}
			if u < 0 || width[u] == 0 { break }
			settled[u] = true
			for edge in 0 .. m {
				if edge_from[edge] != u { continue }
				v := edge_to[edge]
				if settled[v] { continue }
				mut candidate := width[u]
				if edge_capacity[edge] < candidate { candidate = edge_capacity[edge] }
				if candidate > width[v] { width[v] = candidate }
			}
		}
		for vertex in 0 .. n {
			bits := u64(width[vertex])
			for byte in 0 .. 8 { output[8*vertex+byte] = u8((bits >> (8*byte)) & 255) }
		}
		return i64(output_bytes)
	}
}
