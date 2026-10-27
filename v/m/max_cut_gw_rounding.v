@[export: 'max_cut_gw_rounding']
pub fn max_cut_gw_rounding(input &i64, length usize, output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > 431 { return -1 }
		n64, m64, d64 := input[0], input[1], input[2]
		if n64 < 2 || n64 > 16 || m64 < 0 || m64 > 120 || d64 < 1 || d64 > 4 ||
			length != usize(3+3*m64+n64*d64+d64) { return -1 }
		n, m, d := int(n64), int(m64), int(d64)
		mut edge_u := []i64{len: 120, init: 0}
		mut edge_v := []i64{len: 120, init: 0}
		mut edge_weight := []i64{len: 120, init: 0}
		mut previous_u := i64(-1)
		mut previous_v := i64(-1)
		for edge in 0 .. m {
			u, v, weight := input[3+3*edge], input[4+3*edge], input[5+3*edge]
			if u < 0 || v <= u || v >= n64 || weight < 1 || weight > 10000 ||
				u < previous_u || (u == previous_u && v <= previous_v) { return -1 }
			previous_u, previous_v = u, v
			edge_u[edge], edge_v[edge], edge_weight[edge] = u, v, weight
		}
		vector_offset := 3 + 3*m
		mut vectors := [][]i64{}
		for _ in 0 .. 16 { vectors << []i64{len: 4, init: 0} }
		mut normal := []i64{len: 4, init: 0}
		mut common_norm := i64(0)
		for vertex in 0 .. n {
			mut norm := i64(0)
			for axis in 0 .. d {
				coordinate := input[vector_offset+vertex*d+axis]
				if coordinate < -100 || coordinate > 100 { return -1 }
				vectors[vertex][axis] = coordinate
				norm += coordinate*coordinate
			}
			if vertex == 0 { common_norm = norm } else if norm != common_norm { return -1 }
		}
		if common_norm == 0 { return -1 }
		mut has_normal := false
		for axis in 0 .. d {
			normal[axis] = input[vector_offset+n*d+axis]
			if normal[axis] < -100 || normal[axis] > 100 { return -1 }
			if normal[axis] != 0 { has_normal = true }
		}
		if !has_normal { return -1 }
		output_bytes := 8*(n+1)
		if output == nil || capacity < usize(output_bytes) { return -2 }
		mut side := []i64{len: 16, init: 0}
		for vertex in 0 .. n {
			mut projection := i64(0)
			for axis in 0 .. d { projection += vectors[vertex][axis]*normal[axis] }
			if projection > 0 { side[vertex] = 1 }
		}
		mut cut := i64(0)
		for edge in 0 .. m {
			if side[int(edge_u[edge])] != side[int(edge_v[edge])] { cut += edge_weight[edge] }
		}
		values := []i64{len: n+1, init: 0}
		values[0] = cut
		for vertex in 0 .. n { values[vertex+1] = side[vertex] }
		for index, value in values {
			bits := u64(value)
			for byte in 0 .. 8 { output[8*index+byte] = u8((bits >> (8*byte)) & 255) }
		}
		return i64(output_bytes)
	}
}
