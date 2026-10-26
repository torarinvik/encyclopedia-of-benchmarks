@[export: 'max_cut_sahni_gonzalez']
pub fn max_cut_sahni_gonzalez(input &i64, length usize, output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > 362 { return -1 }
		n64 := input[0]
		m64 := input[1]
		if n64 < 1 || n64 > 16 || m64 < 0 || m64 > 120 || length != usize(2+3*m64) { return -1 }
		n := int(n64)
		m := int(m64)
		mut weights := [][]i64{}
		mut seen := [][]bool{}
		for _ in 0 .. 16 {
			weights << []i64{len: 16, init: 0}
			seen << []bool{len: 16, init: false}
		}
		for edge in 0 .. m {
			u64 := input[2+3*edge]
			v64 := input[3+3*edge]
			weight := input[4+3*edge]
			if u64 < 0 || v64 <= u64 || v64 >= n64 || weight < 0 || weight > 10000 { return -1 }
			u := int(u64)
			v := int(v64)
			if seen[u][v] { return -1 }
			seen[u][v] = true
			weights[u][v] = weight
			weights[v][u] = weight
		}
		output_bytes := 8*(n+1)
		if output == nil || capacity < usize(output_bytes) { return -2 }
		mut side := []i64{len: 16, init: 0}
		for vertex in 0 .. n {
			mut put_zero := i64(0)
			mut put_one := i64(0)
			for prior in 0 .. vertex {
				if side[prior] == 1 { put_zero += weights[prior][vertex] } else { put_one += weights[prior][vertex] }
			}
			if put_one > put_zero { side[vertex] = 1 }
		}
		mut cut := i64(0)
		for u in 0 .. n {
			for v in (u+1) .. n {
				if side[u] != side[v] { cut += weights[u][v] }
			}
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
